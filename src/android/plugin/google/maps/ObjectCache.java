package plugin.google.maps;

import androidx.collection.LruCache;

import java.util.HashSet;
import java.util.Set;

public class ObjectCache {
  private final HashSet<String> keys = new HashSet<String>();
  private LruCache<String, Object> objects = new LruCache<String, Object>(1024 * 1024 * 10);

  // Return a snapshot so callers can iterate while background tasks update the cache.
  public synchronized Set<String> getKeys() {
    return new HashSet<String>(keys);
  }

  public synchronized boolean containsKey(String key) {
    return keys.contains(key);
  }

  public synchronized void put(String key, Object object) {
    keys.add(key);
    objects.put(key, object);
  }

  public synchronized Object remove(String key) {
    keys.remove(key);
    return objects.remove(key);
  }

  public synchronized Object get(String key) {
    return objects.get(key);
  }

  public synchronized int size() {
    return objects.size();
  }


  public synchronized void clear() {
    for (String key : keys) {
      objects.remove(key);
    }
    keys.clear();
  }

  public synchronized void destroy() {
    objects.evictAll();
  }


}
