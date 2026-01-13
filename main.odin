package main

import "core:fmt"
import "core:math"
import "core:strings"
import "vendor:raylib"


// makes 1000 to 1,000
format_commas :: proc(val: f64) -> string {
    // Convert to absolute integer to handle digits
    n := i64(val)
    if n == 0 do return "0"

    // Use a fixed buffer on the stack (max i64 is ~20 digits + commas + sign)
    buf: [32]byte
    cursor := len(buf)
    
    is_negative := n < 0
    abs_n := abs(n)
    
    count := 0
    for abs_n > 0 {
        // Add comma every 3 digits, but not at the very start
        if count > 0 && count % 3 == 0 {
            cursor -= 1
            buf[cursor] = ','
        }
        
        // Extract last digit
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

    // Allocate the result from the temp_allocator to match your original API
    result := strings.clone(string(buf[cursor:]), context.temp_allocator)
    return result
}

Upgrade :: struct {
	name:         string,
	count:        i32,
	base_cost:    f64,
	base_power:   f64,
	current_cost: f64,
}

gold: f64 = 0

main :: proc() {
	raylib.InitWindow(400, 600, "Odin Idle Clicker")
	raylib.SetTargetFPS(300)
	raylib.SetConfigFlags({.WINDOW_HIGHDPI, .VSYNC_HINT})

	// Define our different miners
	upgrades := [3]Upgrade {
		{name = "Manual Miner", base_cost = 10, base_power = 1.0, current_cost = 10},
		{name = "Steam Drill", base_cost = 100, base_power = 8.0, current_cost = 100},
		{name = "Laser Array", base_cost = 1000, base_power = 50.0, current_cost = 1000},
	}

	for !raylib.WindowShouldClose() {
		// --- 1. UPDATE ---
		dt := raylib.GetFrameTime()

		total_income: f64 = 0
		for &u in upgrades {
			total_income += f64(u.count) * u.base_power
		}
		gold += total_income * f64(dt)

		if raylib.IsMouseButtonPressed(.LEFT) {
			m_pos := raylib.GetMousePosition()

			// Big Click Area
			if m_pos.y < 200 {
				gold += 1
			}

			// Check Upgrade Buttons
			for &u, i in upgrades {
				// Button box logic: x=20, y=250 + (i*60), width=360, height=50
				rect := raylib.Rectangle{20, f32(250 + (i * 60)), 360, 50}
				if raylib.CheckCollisionPointRec(m_pos, rect) {
					if gold >= u.current_cost {
						gold -= u.current_cost
						u.count += 1
						u.current_cost = u.base_cost * math.pow(1.15, f64(u.count))
					}
				}
			}
		}

		// --- 2. DRAW ---
		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.RAYWHITE)

		raylib.DrawText("AURUM", 160, 20, 20, raylib.GRAY)
		raylib.DrawText(fmt.ctprintf("%s", format_commas(gold)), 120, 50, 40, raylib.GOLD)
		raylib.DrawText(
			fmt.ctprintf("Income: %s/s", format_commas(total_income)),
			140,
			100,
			15,
			raylib.GREEN,
		)

		// Clicker Zone
		raylib.DrawRectangle(40, 130, 320, 60, raylib.LIGHTGRAY)
		raylib.DrawText("MINE GOLD", 150, 150, 20, raylib.DARKGRAY)

		// Upgrade Menu
		for &u, i in upgrades {
			y_pos := f32(250 + (i * 60))
			color := gold >= u.current_cost ? raylib.SKYBLUE : raylib.LIGHTGRAY

			// Draw Button
			raylib.DrawRectangleRec({20, y_pos, 360, 50}, color)
			raylib.DrawRectangleLinesEx({20, y_pos, 360, 50}, 2, raylib.DARKBLUE)

			// Text inside button
			name_label := fmt.ctprintf("%s (Owned: %d)", u.name, u.count)
			cost_label := fmt.ctprintf("Cost: %s", format_commas(u.current_cost))

			raylib.DrawText(name_label, 30, i32(y_pos) + 10, 18, raylib.BLACK)
			raylib.DrawText(cost_label, 30, i32(y_pos) + 30, 14, raylib.DARKGRAY)
		}

		raylib.EndDrawing()
	}
	raylib.CloseWindow()
}
