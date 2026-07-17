#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
output_dir="${1:-${repo_root}/.omx/evidence/m0/worktree-baseline}"
addon_dir="${repo_root}/project-a/addons/godot_ai"

mkdir -p "${output_dir}"

git -C "${repo_root}" status --porcelain=v2 -z --untracked-files=all > "${output_dir}/status-v2.nul"
git -C "${repo_root}" diff --binary > "${output_dir}/unstaged.patch"
git -C "${repo_root}" diff --cached --binary > "${output_dir}/staged.patch"
git -C "${repo_root}" diff --name-only -z > "${output_dir}/unstaged-paths.nul"
git -C "${repo_root}" diff --cached --name-only -z > "${output_dir}/staged-paths.nul"
git -C "${repo_root}" ls-files -z --others --exclude-standard > "${output_dir}/untracked-paths.nul"

cat \
    "${output_dir}/unstaged-paths.nul" \
    "${output_dir}/staged-paths.nul" \
    "${output_dir}/untracked-paths.nul" \
    | LC_ALL=C sort -zu > "${output_dir}/dirty-untracked-paths.nul"

: > "${output_dir}/dirty-untracked-hashes.nul"
while IFS= read -r -d '' relative_path; do
    absolute_path="${repo_root}/${relative_path}"
    if [[ -f "${absolute_path}" ]]; then
        hash="$(shasum -a 256 "${absolute_path}" | awk '{print $1}')"
    else
        hash="MISSING"
    fi
    printf '%s\0%s\0' "${hash}" "${relative_path}" \
        >> "${output_dir}/dirty-untracked-hashes.nul"
done < "${output_dir}/dirty-untracked-paths.nul"

printf '%s\0' \
    'project-a/.editorconfig' \
    'project-a/.gitattributes' \
    'project-a/.gitignore' \
    'project-a/project.godot' \
    'project-a/export_presets.cfg' \
    'project-a/icon.svg' \
    'project-a/icon.svg.import' \
    'project-a/build/android/fantasy_idle-debug.apk' \
    > "${output_dir}/expected-artifact-paths.nul"
if [[ -d "${repo_root}/project-a/build" ]]; then
    find "${repo_root}/project-a/build" -type f -print0 \
        | while IFS= read -r -d '' absolute_path; do
            printf '%s\0' "${absolute_path#"${repo_root}/"}"
        done >> "${output_dir}/expected-artifact-paths.nul"
fi
LC_ALL=C sort -zu "${output_dir}/expected-artifact-paths.nul" \
    -o "${output_dir}/expected-artifact-paths.nul"

: > "${output_dir}/artifact-hashes.nul"
while IFS= read -r -d '' relative_path; do
    absolute_path="${repo_root}/${relative_path}"
    if [[ -f "${absolute_path}" ]]; then
        hash="$(shasum -a 256 "${absolute_path}" | awk '{print $1}')"
    else
        hash="MISSING"
    fi
    printf '%s\0%s\0' "${hash}" "${relative_path}" \
        >> "${output_dir}/artifact-hashes.nul"
done < "${output_dir}/expected-artifact-paths.nul"

: > "${output_dir}/addon-manifest.nul"
while IFS= read -r -d '' path; do
    hash="$(shasum -a 256 "${path}" | awk '{print $1}')"
    relative_path="${path#"${repo_root}/"}"
    printf '%s\0%s\0' "${hash}" "${relative_path}" >> "${output_dir}/addon-manifest.nul"
done < <(find "${addon_dir}" -type f -print0 | LC_ALL=C sort -z)

{
    printf 'head=%s\n' "$(git -C "${repo_root}" rev-parse HEAD)"
    printf 'captured_at_utc=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'project_godot_sha256=%s\n' "$(shasum -a 256 "${repo_root}/project-a/project.godot" | awk '{print $1}')"
    for artifact in status-v2.nul unstaged.patch staged.patch unstaged-paths.nul staged-paths.nul untracked-paths.nul dirty-untracked-paths.nul dirty-untracked-hashes.nul expected-artifact-paths.nul artifact-hashes.nul addon-manifest.nul; do
        printf '%s_sha256=%s\n' "${artifact}" "$(shasum -a 256 "${output_dir}/${artifact}" | awk '{print $1}')"
    done
} > "${output_dir}/summary.txt"

printf 'M0 worktree baseline: %s\n' "${output_dir}"
shasum -a 256 "${output_dir}/summary.txt"
