package main

import "vendor:raylib"

Game_Tab :: enum {
    MINING,
    FACTORY,
    UPGRADES,
}

Ore_Type :: enum {
    IRON,
    IRON_BAR,
    GOLD,
    CRYSTAL,
}

Ore :: struct {
    count: f64,
    value: f64,
    name:  string,
    color: raylib.Color,
}

Upgrade :: struct {
    name:         string,
    count:        int,
    target_ore:   Ore_Type, 
    base_cost:    f64,   
    current_cost: f64,     
    base_power:   f64,   
}

Global_Upgrade :: struct {
    name:       string,
    desc:       string,
    cost:       f64,
    multiplier: f64,
    bought:     bool,
}

Particle :: struct {
    pos:   [2]f32,
    vel:   [2]f32,
    life:  f32,
    color: raylib.Color,
    text:  string,
    size:  f32,
}