# Resource/runtime pair

Use for item definitions, abilities, meters, stats, or other data where many runtime instances may
share one configuration Resource. Avoid storing mutable per-instance state back into the shared
Resource.

Copy the definition, `.tres`, and runtime class. Replace the meter fields with the feature's real
configuration and keep runtime mutation in a separate object.
