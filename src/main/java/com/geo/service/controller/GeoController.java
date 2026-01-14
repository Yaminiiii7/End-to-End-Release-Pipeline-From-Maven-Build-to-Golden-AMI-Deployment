package com.geo.service.controller;

import com.geo.service.model.Location;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GeoController {

    @GetMapping("/health")
    public String healthCheck() {
        return "OK";
    }

    @GetMapping("/location")
    public Location getLocation(
            @RequestParam double lat,
            @RequestParam double lon) {

        return new Location(lat, lon);
    }
}
