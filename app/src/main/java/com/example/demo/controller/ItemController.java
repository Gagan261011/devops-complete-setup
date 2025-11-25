package com.example.demo.controller;

import com.example.demo.model.Item;
import com.example.demo.service.ItemService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/items")
public class ItemController {
    private final ItemService itemService;

    public ItemController(ItemService itemService) {
        this.itemService = itemService;
    }

    @GetMapping
    public List<Item> list() {
        return itemService.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Item> get(@PathVariable Long id) {
        Item item = itemService.findById(id);
        return item != null ? ResponseEntity.ok(item) : ResponseEntity.notFound().build();
    }

    @PostMapping
    public ResponseEntity<Item> create(@RequestBody Item item) {
        return ResponseEntity.ok(itemService.create(item));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Item> update(@PathVariable Long id, @RequestBody Item item) {
        Item updated = itemService.update(id, item);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        return itemService.delete(id) ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        Map<String, String> payload = new HashMap<>();
        payload.put("status", "ok");
        return payload;
    }
}
