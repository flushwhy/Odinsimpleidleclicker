package main

import "core:fmt"
import "core:math"
import "core:strings"
import "vendor:raylib"

// --- TYPES ---

Game_Tab :: enum { MINING, FACTORY }

Upgrade :: struct {
    name:         string,
    count:        i32,
    base_cost:    f64,
    base_power:   f64, // For miners: Ore/s | For factories: Aurum/s
    current_cost: f64,
}
// --- STATE ---

aurum: f64 = 0
ore:   f64 = 0
current_tab := Game_Tab.MINING

// --- UTILS ---

format_commas :: proc(val: f64) -> string {
    n := i64(val)
    if n == 0 do return "0"
    buf: [32]byte
    cursor := len(buf)
    is_negative := n < 0
    abs_n := abs(n)
    count := 0
    for abs_n > 0 {
        if count > 0 && count % 3 == 0 {
            cursor -= 1
            buf[cursor] = ','
        }
        digit := byte(abs_n % 10)
        cursor -= 1
        buf[cursor] = '0' + digit
        abs_n /= 10
        count += 1
    }
    if is_negative {
        cursor -= 1
        buf[cursor] = '-'
    }
    return strings.clone(string(buf[cursor:]), context.temp_allocator)
}

main :: proc() {
    raylib.InitWindow(400, 650, "Odin Idle Clicker")
    raylib.SetTargetFPS(60)
    raylib.SetConfigFlags({.WINDOW_HIGHDPI, .SYNC_VSYNC_HINT})

    miners := [3]Upgrade {
        {name = "Manual Miner", base_cost = 15, base_power = 1.0, current_cost = 15},
        {name = "Steam Drill",  base_cost = 150, base_power = 10.0, current_cost = 150},
        {name = "Laser Array",  base_cost = 2000, base_power = 75.0, current_cost = 2000},
    }

    factories := [2]Upgrade {
        {name = "Smelter",      base_cost = 100, base_power = 5.0, current_cost = 100},
        {name = "Jewelry Shop", base_cost = 1200, base_power = 40.0, current_cost = 1200},
    }

    for !raylib.WindowShouldClose() {
        dt := f64(raylib.GetFrameTime())

        ore_income: f64 = 0
        for &m in miners {
            ore_income += f64(m.count) * m.base_power
        }
        ore += ore_income * dt
        factory_income: f64 = 0
        for &f in factories {
            factory_income += f64(f.count) * f.base_power
        }
        
        if ore > factory_income * dt {
            aurum += factory_income * dt
            ore -= factory_income * dt
        }

        if raylib.IsMouseButtonPressed(.LEFT) {
            m_pos := raylib.GetMousePosition()

            // Tab Switching
            if raylib.CheckCollisionPointRec(m_pos, {20, 180, 170, 40}) do current_tab = .MINING
            if raylib.CheckCollisionPointRec(m_pos, {210, 180, 170, 40}) do current_tab = .FACTORY

            // Action Buttons
            if current_tab == .MINING {
                if raylib.CheckCollisionPointRec(m_pos, {40, 110, 320, 50}) {
                    ore += 1
                }
                for &u, i in miners {
                    rect := raylib.Rectangle{20, f32(240 + (i * 70)), 360, 60}
                    if raylib.CheckCollisionPointRec(m_pos, rect) && aurum >= u.current_cost {
                        aurum -= u.current_cost
                        u.count += 1
                        u.current_cost = u.base_cost * math.pow(1.15, f64(u.count))
                    }
                }
            } else {
                // Sell Ore Button (1 Ore = 0.5 Aurum)
                if raylib.CheckCollisionPointRec(m_pos, {40, 110, 320, 50}) {
                    aurum += (ore * 0.5)
                    ore = 0
                }
                for &u, i in factories {
                    rect := raylib.Rectangle{20, f32(240 + (i * 70)), 360, 60}
                    if raylib.CheckCollisionPointRec(m_pos, rect) && aurum >= u.current_cost {
                        aurum -= u.current_cost
                        u.count += 1
                        u.current_cost = u.base_cost * math.pow(1.15, f64(u.count))
                    }
                }
            }
        }
        
        raylib.BeginDrawing()
        raylib.ClearBackground({30, 30, 35, 255})

        // HUD
        raylib.DrawText("AURUM:", 20, 20, 20, raylib.GOLD)
        raylib.DrawText(fmt.ctprintf("%s", format_commas(aurum)), 20, 45, 30, raylib.WHITE)
        
        raylib.DrawText("ORE:", 220, 20, 20, raylib.LIGHTGRAY)
        raylib.DrawText(fmt.ctprintf("%s", format_commas(ore)), 220, 45, 30, raylib.WHITE)

        // Tabs
        raylib.DrawRectangle(20, 180, 170, 40, current_tab == .MINING ? raylib.DARKGRAY : raylib.BLACK)
        raylib.DrawRectangle(210, 180, 170, 40, current_tab == .FACTORY ? raylib.DARKGRAY : raylib.BLACK)
        raylib.DrawText("MINING", 65, 190, 20, raylib.WHITE)
        raylib.DrawText("FACTORY", 250, 190, 20, raylib.WHITE)

        if current_tab == .MINING {
            raylib.DrawRectangle(40, 110, 320, 50, raylib.GRAY)
            raylib.DrawText("MINE ORE (+1)", 130, 125, 20, raylib.WHITE)
            
            for &u, i in miners {
                y_pos := f32(240 + (i * 70))
                color := aurum >= u.current_cost ? raylib.DARKBLUE : raylib.MAROON
                raylib.DrawRectangleRec({20, y_pos, 360, 60}, color)
                raylib.DrawText(fmt.ctprintf("%s (%d)", u.name, u.count), 35, i32(y_pos) + 10, 20, raylib.WHITE)
                raylib.DrawText(fmt.ctprintf("Cost: %s Aurum | +%v ore/s", format_commas(u.current_cost), u.base_power), 35, i32(y_pos) + 35, 15, raylib.LIGHTGRAY)
            }
        } else {
            raylib.DrawRectangle(40, 110, 320, 50, raylib.GOLD)
            raylib.DrawText("SELL ALL ORE", 135, 125, 20, raylib.BLACK)

            for &u, i in factories {
                y_pos := f32(240 + (i * 70))
                color := aurum >= u.current_cost ? raylib.DARKGREEN : raylib.MAROON
                raylib.DrawRectangleRec({20, y_pos, 360, 60}, color)
                raylib.DrawText(fmt.ctprintf("%s (%d)", u.name, u.count), 35, i32(y_pos) + 10, 20, raylib.WHITE)
                raylib.DrawText(fmt.ctprintf("Cost: %s Aurum | Consumes Ore for Aurum", format_commas(u.current_cost)), 35, i32(y_pos) + 35, 14, raylib.LIGHTGRAY)
            }
        }

        raylib.EndDrawing()
    }
    raylib.CloseWindow()
}