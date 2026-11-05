# Android object cache regression test

`ObjectCacheTest.java` checks that key snapshots are isolated from cache changes
and exercises concurrent writes, snapshot iteration, removals, and clearing.
It runs on a JDK with the AndroidX collection JAR used by the plugin.

From the repository root, set `ANDROIDX_COLLECTION_JAR` to the path of that JAR,
then run:

```sh
build_dir=$(mktemp -d)
javac -cp "$ANDROIDX_COLLECTION_JAR" -d "$build_dir" \
  src/android/plugin/google/maps/ObjectCache.java tests/android/ObjectCacheTest.java
java -cp "$build_dir:$ANDROIDX_COLLECTION_JAR" plugin.google.maps.ObjectCacheTest
```

This standalone test does not replace a build or runtime test of the plugin on
Android, whose `HashSet.toArray()` implementation can differ from the host JDK.
