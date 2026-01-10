package main

import "vendor:raylib"
import "core:fmt"
import "core:strings"

// --- Helper: Format 1000 to "1,000" ---
format_commas :: proc(val: f64) -> string {
    n := i64(val)
    s := fmt.tprintf("%d", n)
    
    if len(s) <= 3 do return s

    builder := strings.builder_make(context.temp_allocator)
    
    for i := 0; i < len(s); i += 1 {

        if i > 0 && (len(s) - i) % 3 == 0 {
            strings.write_byte(&builder, ',')
        }
        strings.write_byte(&builder, s[i])
    }
    
    return strings.to_string(builder)
}


gold: f64 = 0
auto_income: f64 = 0
miner_count: i32 = 0
miner_cost: f64 = 10

main :: proc() {
    raylib.InitWindow(400, 500, "Odin Idle Clicker")
    raylib.SetTargetFPS(60)

    for !raylib.WindowShouldClose() {
        // --- UPDATE ---
        dt := raylib.GetFrameTime()
        gold += auto_income * f64(dt)

        if raylib.IsMouseButtonPressed(.LEFT) && raylib.GetMousePosition().y < 250 {
            gold += 1
        }

        if raylib.IsKeyPressed(.M) && gold >= miner_cost {
            gold -= miner_cost
            miner_count += 1
            auto_income += 2.5
            miner_cost *= 1.15 
        }

        // --- DRAW ---
        raylib.BeginDrawing()
        raylib.ClearBackground(raylib.RAYWHITE)

        // Using our new formatter
        gold_str := format_commas(gold)
        cost_str := format_commas(miner_cost)

        raylib.DrawText("Aurum", 150, 40, 20, raylib.GRAY)
        raylib.DrawText(fmt.ctprintf("%s", gold_str), 120, 70, 40, raylib.GOLD)

        // Click Area
        raylib.DrawRectangle(50, 130, 300, 100, raylib.LIGHTGRAY)
        raylib.DrawText("CLICK ME", 155, 170, 20, raylib.DARKGRAY)

        // Upgrades
        raylib.DrawText("UPGRADES", 20, 280, 20, raylib.BLACK)
        
        miner_label := fmt.ctprintf("Miners: %d (Cost: %s)", miner_count, cost_str)
        raylib.DrawText(miner_label, 20, 320, 18, raylib.DARKBLUE)
        
        income_label := fmt.ctprintf("Income: %s/sec", format_commas(auto_income))
        raylib.DrawText(income_label, 20, 450, 20, raylib.GREEN)

        raylib.EndDrawing()
    }
    raylib.CloseWindow()
}