package com.example.demo.service;

import com.example.demo.model.Item;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class ItemService {
    private final Map<Long, Item> store = new ConcurrentHashMap<>();
    private final AtomicLong idSequence = new AtomicLong(0);

    public List<Item> findAll() {
        return Collections.unmodifiableList(new ArrayList<>(store.values()));
    }

    public Item findById(Long id) {
        return store.get(id);
    }

    public Item create(Item item) {
        long id = idSequence.incrementAndGet();
        Item saved = new Item(id, item.getName(), item.getDescription());
        store.put(id, saved);
        return saved;
    }

    public Item update(Long id, Item item) {
        if (!store.containsKey(id)) {
            return null;
        }
        Item updated = new Item(id, item.getName(), item.getDescription());
        store.put(id, updated);
        return updated;
    }

    public boolean delete(Long id) {
        return store.remove(id) != null;
    }
}
