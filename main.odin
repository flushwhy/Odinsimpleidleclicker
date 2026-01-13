package main

import "core:fmt"
import "core:strings"
import "vendor:raylib"

// --- TYPES ---

Game_Tab :: enum { MINING, FACTORY }
Ore_Type :: enum { IRON, GOLD, CRYSTAL }

Ore :: struct {
    name:  string,
    count: f64,
    color: raylib.Color,
    value: f64,
}

Upgrade :: struct {
    name:         string,
    target_ore:   Ore_Type,
    count:        i32,
    base_cost:    f64,
    base_power:   f64, 
    current_cost: f64,
}

// --- STATE ---

aurum: f64 = 0
current_tab := Game_Tab.MINING

// Global inventory
ores := [Ore_Type]Ore{
    .IRON    = { name = "Iron",    count = 0, color = raylib.LIGHTGRAY, value = 0.5 },
    .GOLD    = { name = "Gold",    count = 0, color = raylib.GOLD,      value = 2.0 },
    .CRYSTAL = { name = "Crystal", count = 0, color = raylib.SKYBLUE,   value = 5.0 },
}

// --- UTILS ---

format_commas :: proc(val: f64) -> string {
    n := i64(val)
    if n == 0 do return "0"
    buf: [32]byte
    cursor := len(buf)
    abs_n := abs(n)
    count := 0
    for abs_n > 0 {
        if count > 0 && count % 3 == 0 {
            cursor -= 1
            buf[cursor] = ','
        }
        cursor -= 1
        buf[cursor] = '0' + byte(abs_n % 10)
        abs_n /= 10
        count += 1
    }
    if n < 0 { cursor -= 1; buf[cursor] = '-' }
    return strings.clone(string(buf[cursor:]), context.temp_allocator)
}

main :: proc() {
    raylib.InitWindow(400, 800, "Odin Idle Clicker")
    raylib.SetTargetFPS(60)

    miners := [6]Upgrade {
        {name = "Iron Pick",    target_ore = .IRON,    base_cost = 15,    base_power = 1.0,  current_cost = 15},
        {name = "Iron Drill",   target_ore = .IRON,    base_cost = 200,   base_power = 12.0, current_cost = 200},
        {name = "Gold Pick",    target_ore = .GOLD,   base_cost = 300,   base_power = 2.0,  current_cost = 300},
        {name = "Gold Drill",   target_ore = .GOLD,    base_cost = 500,   base_power = 15.0, current_cost = 500},
        {name = "Crystal Saw",  target_ore = .CRYSTAL, base_cost = 700,   base_power = 0.5,  current_cost = 500},
        {name = "Sonic Carver", target_ore = .CRYSTAL, base_cost = 5000,  base_power = 4.0,  current_cost = 5000},
    }

    factories := [6]Upgrade {
        {name = "Iron Smelter",    target_ore = .IRON,    base_cost = 100,   base_power = 8.0,   current_cost = 100},
        {name = "Iron Foundry",    target_ore = .IRON,    base_cost = 500,   base_power = 20.0,  current_cost = 500},
        {name = "Gold Smelter",    target_ore = .GOLD,    base_cost = 750,   base_power = 15.0,  current_cost = 750},
        {name = "Gold Jeweler",    target_ore = .GOLD,    base_cost = 1000,  base_power = 30.0,  current_cost = 1000},
        {name = "Crystal Lab",     target_ore = .CRYSTAL, base_cost = 2500,  base_power = 50.0,  current_cost = 2500},
        {name = "Crystal Factory", target_ore = .CRYSTAL, base_cost = 10000, base_power = 120.0, current_cost = 10000},
    }

    for !raylib.WindowShouldClose() {
        dt := f64(raylib.GetFrameTime())

        // --- 1. MINING LOGIC ---
        for &m in miners {
            ores[m.target_ore].count += (f64(m.count) * m.base_power) * dt
        }

        // --- 2. FACTORY LOGIC ---
        for &f in factories {
            production_needed := (f64(f.count) * f.base_power) * dt
            if ores[f.target_ore].count >= production_needed {
                aurum += production_needed
                ores[f.target_ore].count -= production_needed
            }
        }

        if raylib.IsMouseButtonPressed(.LEFT) {
            m_pos := raylib.GetMousePosition()

            // Tab Switch
            if raylib.CheckCollisionPointRec(m_pos, {20, 180, 170, 40}) do current_tab = .MINING
            if raylib.CheckCollisionPointRec(m_pos, {210, 180, 170, 40}) do current_tab = .FACTORY

            if current_tab == .MINING {
                if raylib.CheckCollisionPointRec(m_pos, {40, 110, 320, 50}) { ores[.IRON].count += 1 }
                for &u, i in miners {
                    rect := raylib.Rectangle{20, f32(240 + (i * 85)), 360, 75} 
                    if raylib.CheckCollisionPointRec(m_pos, rect) && aurum >= u.current_cost {
                        aurum -= u.current_cost
                        u.count += 1
                        u.current_cost *= 1.15
                    }
                }
            } else {
                if raylib.CheckCollisionPointRec(m_pos, {20, 110, 110, 50}) {
                    aurum += ores[.IRON].count * ores[.IRON].value
                    ores[.IRON].count = 0
                }
                if raylib.CheckCollisionPointRec(m_pos, {145, 110, 110, 50}) {
                    aurum += ores[.GOLD].count * ores[.GOLD].value
                    ores[.GOLD].count = 0
                }
                if raylib.CheckCollisionPointRec(m_pos, {270, 110, 110, 50}) {
                    aurum += ores[.CRYSTAL].count * ores[.CRYSTAL].value
                    ores[.CRYSTAL].count = 0
                }
                
                for &u, i in factories {
                    rect := raylib.Rectangle{20, f32(240 + (i * 85)), 360, 75}
                    if raylib.CheckCollisionPointRec(m_pos, rect) && aurum >= u.current_cost {
                        aurum -= u.current_cost
                        u.count += 1
                        u.current_cost *= 1.20
                    }
                }
            }
        }

        // --- 3. DRAWING ---
        raylib.BeginDrawing()
        raylib.ClearBackground({25, 25, 30, 255})

        // HUD
        raylib.DrawText("AURUM BANK", 20, 15, 15, raylib.GOLD)
        raylib.DrawText(fmt.ctprintf("$ %s", format_commas(aurum)), 20, 35, 35, raylib.WHITE)
        
        // Resource Bar (Three columns)
        raylib.DrawRectangle(0, 80, 400, 25, {40, 40, 45, 255})
        raylib.DrawText(fmt.ctprintf("Fe: %s", format_commas(ores[.IRON].count)), 10, 85, 15, ores[.IRON].color)
        raylib.DrawText(fmt.ctprintf("Au: %s", format_commas(ores[.GOLD].count)), 145, 85, 15, ores[.GOLD].color)
        raylib.DrawText(fmt.ctprintf("Cr: %s", format_commas(ores[.CRYSTAL].count)), 280, 85, 15, ores[.CRYSTAL].color)

        // Tabs
        raylib.DrawRectangle(20, 180, 170, 40, current_tab == .MINING ? raylib.DARKGRAY : raylib.BLACK)
        raylib.DrawRectangle(210, 180, 170, 40, current_tab == .FACTORY ? raylib.DARKGRAY : raylib.BLACK)
        raylib.DrawText("MINING", 65, 190, 20, raylib.WHITE)
        raylib.DrawText("FACTORY", 250, 190, 20, raylib.WHITE)

        if current_tab == .MINING {
            raylib.DrawRectangle(40, 110, 320, 50, raylib.GRAY)
            raylib.DrawText("CHIP IRON (+1)", 135, 125, 20, raylib.WHITE)
            for &u, i in miners {
                y := f32(240 + (i * 85))
                raylib.DrawRectangleRec({20, y, 360, 75}, aurum >= u.current_cost ? raylib.DARKBLUE : raylib.MAROON)
                raylib.DrawText(fmt.ctprintf("%s (%d)", u.name, u.count), 35, i32(y)+12, 20, raylib.WHITE)
                raylib.DrawText(fmt.ctprintf("Cost: %s | +%v %s/s", format_commas(u.current_cost), u.base_power, ores[u.target_ore].name), 35, i32(y)+45, 14, raylib.LIGHTGRAY)
            }
        } else {
            // Three Sell Buttons
            raylib.DrawRectangle(20, 110, 110, 50, raylib.GRAY)
            raylib.DrawText("SELL IRON", 35, 128, 12, raylib.WHITE)
            
            raylib.DrawRectangle(145, 110, 110, 50, raylib.GOLD)
            raylib.DrawText("SELL GOLD", 165, 128, 12, raylib.BLACK)
            
            raylib.DrawRectangle(270, 110, 110, 50, raylib.SKYBLUE)
            raylib.DrawText("SELL CRYSTAL", 282, 128, 12, raylib.BLACK)

            for &u, i in factories {
                y := f32(240 + (i * 85))
                raylib.DrawRectangleRec({20, y, 360, 75}, aurum >= u.current_cost ? raylib.DARKGREEN : raylib.MAROON)
                raylib.DrawText(fmt.ctprintf("%s (%d)", u.name, u.count), 35, i32(y)+12, 20, raylib.WHITE)
                raylib.DrawText(fmt.ctprintf("Cost: %s | Consumes %s", format_commas(u.current_cost), ores[u.target_ore].name), 35, i32(y)+45, 13, raylib.LIGHTGRAY)
            }
        }
        raylib.EndDrawing()
    }
    raylib.CloseWindow()
}