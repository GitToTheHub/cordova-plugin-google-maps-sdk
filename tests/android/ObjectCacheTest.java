package plugin.google.maps;

import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

/** Standalone regression test; compile with ObjectCache.java and AndroidX collection on the classpath. */
public class ObjectCacheTest {
  public static void main(String[] args) throws Exception {
    ObjectCache cache = new ObjectCache();
    cache.put("marker_1", new Object());
    Set<String> snapshot = cache.getKeys();
    cache.put("marker_2", new Object());
    cache.remove("marker_1");
    if (snapshot.size() != 1 || !snapshot.contains("marker_1")) {
      throw new AssertionError("Cache mutations changed an existing snapshot");
    }
    snapshot.clear();
    if (!cache.containsKey("marker_2")) {
      throw new AssertionError("Snapshot mutations changed the cache");
    }
    cache.clear();

    ExecutorService workers = Executors.newFixedThreadPool(3);
    CountDownLatch start = new CountDownLatch(1);
    try {
      Future<?> writer = workers.submit(() -> {
        await(start);
        for (int i = 0; i < 100000; i++) {
          String key = "marker_" + (i % 100);
          cache.put(key, new Object());
          cache.remove(key);
        }
      });
      Future<?> reader = workers.submit(() -> {
        await(start);
        for (int i = 0; i < 100000; i++) {
          Set<String> keys = cache.getKeys();
          String[] ids = keys.toArray(new String[keys.size()]);
          for (String id : ids) {
            if (id == null) {
              throw new AssertionError("Snapshot contains a null key");
            }
            cache.remove(id);
          }
        }
      });
      Future<?> clearer = workers.submit(() -> {
        await(start);
        for (int i = 0; i < 100000; i++) {
          cache.clear();
        }
      });
      start.countDown();
      writer.get();
      reader.get();
      clearer.get();
    } finally {
      workers.shutdownNow();
    }
    cache.clear();
    if (cache.size() != 0 || !cache.getKeys().isEmpty()) {
      throw new AssertionError("Cleared cache still contains entries");
    }
    System.out.println("ObjectCache snapshot and concurrency tests passed");
  }

  private static void await(CountDownLatch latch) {
    try {
      latch.await();
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new AssertionError(e);
    }
  }
}
