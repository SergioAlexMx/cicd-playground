package com.salvarez.cdcdplayground.demo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/ping")
class PingController {

    @GetMapping
    public Map<String, String> ping() {
        Map<String, String> map = new HashMap<>();
        map.put("status", "ok");
        map.put("message", "pong");
        return map;
    }

}
