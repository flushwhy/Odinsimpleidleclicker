package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import "vendor:raylib"

main :: proc() {
    raylib.SetConfigFlags({.MSAA_4X_HINT})
    raylib.InitWindow(400, 800, "Odin Idle Clicker - Pro Modular")
    raylib.SetTargetFPS(60)

    font := raylib.LoadFontEx("fonts/Radio Stars.otf", 48, nil, 0)
    raylib.SetTextureFilter(font.texture, .POINT)
    
    aurum: f64 = 0
    current_tab := Game_Tab.MINING
    particles := make([dynamic]Particle, 0, 500)
    shake_amount: f32 = 0.0
    save_timer: f32 = 0.0
    show_settings := false
    show_credits := false 
    

    settings_btn := raylib.Rectangle{345, 745, 40, 35}
    save_btn     := raylib.Rectangle{285, 745, 50, 35}

    ores := [Ore_Type]Ore{
        .IRON     = { name = "Iron",     count = 0, color = raylib.LIGHTGRAY, value = 0.5 },
        .IRON_BAR = { name = "Iron Bar", count = 0, color = raylib.WHITE,     value = 8.0 },
        .GOLD     = { name = "Gold",     count = 0, color = raylib.GOLD,      value = 2.0 },
        .CRYSTAL  = { name = "Crystal",  count = 0, color = raylib.SKYBLUE,   value = 5.0 },
    }

    miners := [6]Upgrade {
        {name = "IRON PICK",    target_ore = .IRON,    base_cost = 15,    base_power = 1.0,  current_cost = 15},
        {name = "IRON DRILL",   target_ore = .IRON,    base_cost = 200,   base_power = 12.0, current_cost = 200},
        {name = "GOLD PICK",    target_ore = .GOLD,    base_cost = 300,   base_power = 2.0,  current_cost = 300},
        {name = "GOLD DRILL",   target_ore = .GOLD,    base_cost = 500,   base_power = 15.0, current_cost = 500},
        {name = "CRYSTAL SAW",  target_ore = .CRYSTAL, base_cost = 700,   base_power = 5.0,  current_cost = 700},
        {name = "SONIC CARVER", target_ore = .CRYSTAL, base_cost = 5000,  base_power = 25.0, current_cost = 5000},
    }

    factories := [6]Upgrade {
        {name = "IRON SMELTER",    target_ore = .IRON,    base_cost = 100,   base_power = 5.0,   current_cost = 100},
        {name = "IRON FOUNDRY",    target_ore = .IRON,    base_cost = 500,   base_power = 20.0,  current_cost = 500},
        {name = "GOLD SMELTER",    target_ore = .GOLD,    base_cost = 750,   base_power = 15.0,  current_cost = 750},
        {name = "GOLD JEWELER",    target_ore = .GOLD,    base_cost = 1000,  base_power = 30.0,  current_cost = 1000},
        {name = "CRYSTAL LAB",     target_ore = .CRYSTAL, base_cost = 2500,  base_power = 50.0,  current_cost = 2500},
        {name = "CRYSTAL FACTORY", target_ore = .CRYSTAL, base_cost = 10000, base_power = 120.0, current_cost = 10000},
    }

    upgrades := [3]Global_Upgrade {
        {name = "SHARP PICKS", desc = "CLICKING IS 10X STRONGER", cost = 100,  multiplier = 10.0, bought = false},
        {name = "OVERCLOCK",   desc = "ALL MACHINES 50% FASTER",  cost = 1000, multiplier = 1.5,  bought = false},
        {name = "FREE MARKET", desc = "ALL ORES SELL FOR 2X",     cost = 5000, multiplier = 2.0,  bought = false},
    }

    if s_data, ok := load_game(); ok {
        aurum = s_data.aurum
        for count, i in s_data.ore_counts { ores[Ore_Type(i)].count = count }
        for count, i in s_data.miner_counts { 
            miners[i].count = int(count)
            for _ in 0..<int(count) do miners[i].current_cost *= 1.15 
        }
        for count, i in s_data.factory_counts { 
            factories[i].count = int(count)
            for _ in 0..<int(count) do factories[i].current_cost *= 1.20 
        }
        for bought, i in s_data.upgrades_bought do upgrades[i].bought = bought
    }

    tab_w, tab_h, tab_gap, start_x : f32 = 125, 45, 5, 7.5
    rect_mining   := raylib.Rectangle{start_x, 185, tab_w, tab_h}
    rect_factory  := raylib.Rectangle{start_x + tab_w + tab_gap, 185, tab_w, tab_h}
    rect_upgrades := raylib.Rectangle{start_x + (tab_w + tab_gap) * 2, 185, tab_w, tab_h}

    for !raylib.WindowShouldClose() {
        free_all(context.temp_allocator)
        dt := raylib.GetFrameTime()
        
        click_mod := upgrades[0].bought ? upgrades[0].multiplier : 1.0
        speed_mod := upgrades[1].bought ? upgrades[1].multiplier : 1.0
        sell_mod  := upgrades[2].bought ? upgrades[2].multiplier : 1.0

        save_timer += dt
        if save_timer >= 30.0 { save_game(aurum, ores, miners, factories, upgrades); save_timer = 0 }

        for &m in miners { ores[m.target_ore].count += (f64(m.count) * m.base_power * f64(speed_mod)) * f64(dt) }
        for &f in factories {
            prod := (f64(f.count) * f.base_power * f64(speed_mod)) * f64(dt)
            if ores[f.target_ore].count >= prod {
                if f.name == "IRON SMELTER" { ores[.IRON].count -= prod; ores[.IRON_BAR].count += prod }
                else { ores[f.target_ore].count -= prod; aurum += (prod * ores[f.target_ore].value * sell_mod) }
            }
        }

        shake_amount = max(0, shake_amount - dt * 10.0)
        for i := 0; i < len(particles); {
            p := &particles[i]
            p.pos += p.vel * dt
            if p.text == "" do p.vel.y += 600 * dt
            p.life -= dt * 1.5
            if p.life <= 0 do unordered_remove(&particles, i)
            else do i += 1
        }

        if raylib.IsMouseButtonPressed(.LEFT) {
            m_pos := raylib.GetMousePosition()
            
            if show_settings {
                if show_credits {
   
                    if raylib.CheckCollisionPointRec(m_pos, {70, 560, 260, 40}) do show_credits = false
                } else {
      
                    if raylib.CheckCollisionPointRec(m_pos, {70, 440, 260, 50}) do show_credits = true
    
                    if raylib.CheckCollisionPointRec(m_pos, {70, 500, 260, 50}) {
                        os.remove("save.flsh")
                        shake_amount = 15.0
                    }
                }
                if !raylib.CheckCollisionPointRec(m_pos, {50, 200, 300, 420}) { 
                    show_settings = false; show_credits = false 
                }
            } else {
                if raylib.CheckCollisionPointRec(m_pos, settings_btn) {
                    show_settings = !show_settings
                } else if raylib.CheckCollisionPointRec(m_pos, save_btn) {
                    save_game(aurum, ores, miners, factories, upgrades)
                    append(&particles, Particle{pos = {m_pos.x, m_pos.y - 20}, vel = {0, -100}, life = 1.0, color = raylib.GREEN, text = "SAVED!"})
                } else {
                    if raylib.CheckCollisionPointRec(m_pos, rect_mining)   do current_tab = .MINING
                    if raylib.CheckCollisionPointRec(m_pos, rect_factory)  do current_tab = .FACTORY
                    if raylib.CheckCollisionPointRec(m_pos, rect_upgrades) do current_tab = .UPGRADES

                    switch current_tab {
                    case .MINING:
                        if raylib.CheckCollisionPointRec(m_pos, {40, 115, 320, 50}) { 
                            ores[.IRON].count += click_mod 
                            spawn_burst(&particles, m_pos, 5, raylib.LIGHTGRAY)
                            append(&particles, Particle{pos = {m_pos.x, m_pos.y-20}, vel={0,-60}, life=0.8, color=raylib.YELLOW, text=fmt.tprintf("+%v", click_mod)})
                        }
                        for &u, i in miners {
                            rect := raylib.Rectangle{20, f32(245 + (i * 85)), 360, 75} 
                            if raylib.CheckCollisionPointRec(m_pos, rect) && aurum >= u.current_cost {
                                aurum -= u.current_cost; u.count += 1; u.current_cost *= 1.15
                                shake_amount = 3.0; spawn_burst(&particles, m_pos, 15, raylib.SKYBLUE)
                            }
                        }
                    case .FACTORY:
                        sell_btns := [4]raylib.Rectangle{{20,110,85,50}, {115,110,85,50}, {210,110,85,50}, {305,110,85,50}}
                        ore_list := [4]Ore_Type{.IRON, .IRON_BAR, .GOLD, .CRYSTAL}
                        for rect, idx in sell_btns {
                            if raylib.CheckCollisionPointRec(m_pos, rect) && ores[ore_list[idx]].count > 0 {
                                val := ores[ore_list[idx]].count * ores[ore_list[idx]].value * sell_mod
                                aurum += val; ores[ore_list[idx]].count = 0
                                spawn_burst(&particles, m_pos, 10, raylib.GOLD)
                                append(&particles, Particle{pos=m_pos, vel={0,-80}, life=1.0, color=raylib.GREEN, text=fmt.tprintf("+$%s", format_commas(val))})
                            }
                        }
                        for &u, i in factories {
                            rect := raylib.Rectangle{20, f32(245 + (i * 85)), 360, 75}
                            if raylib.CheckCollisionPointRec(m_pos, rect) && aurum >= u.current_cost {
                                aurum -= u.current_cost; u.count += 1; u.current_cost *= 1.20
                                shake_amount = 4.0; spawn_burst(&particles, m_pos, 20, raylib.LIME)
                            }
                        }
                    case .UPGRADES:
                        for &u, i in upgrades {
                            rect := raylib.Rectangle{20, f32(245 + (i * 90)), 360, 80}
                            if raylib.CheckCollisionPointRec(m_pos, rect) && !u.bought && aurum >= u.cost {
                                aurum -= u.cost; u.bought = true
                                shake_amount = 8.0; spawn_burst(&particles, m_pos, 30, raylib.PURPLE)
                            }
                        }
                    }
                }
            }
        }

        // --- DRAWING ---
        raylib.BeginDrawing()
        raylib.ClearBackground({20, 20, 25, 255})
        
        if shake_amount > 0 {
            cam := raylib.Camera2D{ zoom = 1.0, offset = {rand.float32_range(-shake_amount, shake_amount), rand.float32_range(-shake_amount, shake_amount)} }
            raylib.BeginMode2D(cam)
        }

        // Header
        draw_text(font, "AURUM BANK", 25, 15, 20, raylib.GOLD)
        draw_text(font, fmt.tprintf("$ %s", format_commas(aurum)), 25, 38, 32, raylib.WHITE)
        raylib.DrawRectangle(0, 80, 400, 25, {35, 35, 40, 255})
        draw_text(font, fmt.tprintf("FE:%s", format_commas(ores[.IRON].count)), 10, 86, 12, ores[.IRON].color)
        draw_text(font, fmt.tprintf("BAR:%s", format_commas(ores[.IRON_BAR].count)), 110, 86, 12, ores[.IRON_BAR].color)
        draw_text(font, fmt.tprintf("AU:%s", format_commas(ores[.GOLD].count)), 220, 86, 12, ores[.GOLD].color)
        draw_text(font, fmt.tprintf("CR:%s", format_commas(ores[.CRYSTAL].count)), 320, 86, 12, ores[.CRYSTAL].color)

        // Tabs
        raylib.DrawRectangleRec(rect_mining, current_tab == .MINING ? raylib.DARKGRAY : raylib.BLACK)
        draw_centered_text(font, "MINING", rect_mining, 18, raylib.WHITE)
        raylib.DrawRectangleRec(rect_factory, current_tab == .FACTORY ? raylib.DARKGRAY : raylib.BLACK)
        draw_centered_text(font, "FACTORY", rect_factory, 18, raylib.WHITE)
        raylib.DrawRectangleRec(rect_upgrades, current_tab == .UPGRADES ? raylib.DARKGRAY : raylib.BLACK)
        draw_centered_text(font, "UPGRADES", rect_upgrades, 16, raylib.WHITE)

        if current_tab == .MINING {
            chip_rect := raylib.Rectangle{40, 115, 320, 50}
            raylib.DrawRectangleRec(chip_rect, raylib.GRAY)
            draw_centered_text(font, fmt.tprintf("CHIP IRON (+%v)", click_mod), chip_rect, 22, raylib.WHITE)
            for &u, i in miners {
                y := f32(245 + (i * 85))
                raylib.DrawRectangleRec({20, y, 360, 75}, aurum >= u.current_cost ? raylib.MAROON : {60, 20, 20, 255})
                draw_text(font, fmt.tprintf("%s (%d)", u.name, u.count), 35, i32(y)+12, 20, raylib.WHITE)
                draw_text(font, fmt.tprintf("COST: %s | +%v/S", format_commas(u.current_cost), u.base_power * f64(speed_mod)), 35, i32(y)+45, 13, raylib.LIGHTGRAY)
            }
        } else if current_tab == .FACTORY {
            sell_rects := [4]raylib.Rectangle{{20, 110, 85, 50}, {115, 110, 85, 50}, {210, 110, 85, 50}, {305, 110, 85, 50}}
            raylib.DrawRectangleRec(sell_rects[0], raylib.GRAY);      draw_centered_text(font, "IRON", sell_rects[0], 16, raylib.WHITE)
            raylib.DrawRectangleRec(sell_rects[1], raylib.WHITE);     draw_centered_text(font, "BARS", sell_rects[1], 16, raylib.BLACK)
            raylib.DrawRectangleRec(sell_rects[2], raylib.GOLD);      draw_centered_text(font, "GOLD", sell_rects[2], 16, raylib.BLACK)
            raylib.DrawRectangleRec(sell_rects[3], raylib.SKYBLUE);   draw_centered_text(font, "CRYSTAL", sell_rects[3], 14, raylib.BLACK)
            for &u, i in factories {
                y := f32(245 + (i * 85))
                raylib.DrawRectangleRec({20, y, 360, 75}, aurum >= u.current_cost ? {30, 80, 30, 255} : {15, 40, 15, 255})
                draw_text(font, fmt.tprintf("%s (%d)", u.name, u.count), 35, i32(y)+12, 20, raylib.WHITE)
                draw_text(font, fmt.tprintf("COST: %s", format_commas(u.current_cost)), 35, i32(y)+45, 13, raylib.LIGHTGRAY)
            }
        } else {
            for &u, i in upgrades {
                y := f32(245 + (i * 90))
                raylib.DrawRectangleRec({20, y, 360, 80}, u.bought ? raylib.DARKGRAY : (aurum >= u.cost ? raylib.PURPLE : raylib.MAROON))
                draw_text(font, u.name, 35, i32(y)+10, 22, raylib.WHITE)
                draw_text(font, u.desc, 35, i32(y)+38, 12, raylib.LIGHTGRAY)
                draw_text(font, u.bought ? "ACTIVE" : fmt.tprintf("BUY: $%s", format_commas(u.cost)), 35, i32(y)+56, 16, u.bought ? raylib.GREEN : raylib.GOLD)
            }
        }
        
        if shake_amount > 0 do raylib.EndMode2D()

        // Footer Buttons
        raylib.DrawRectangleRec(save_btn, raylib.LIME)
        draw_centered_text(font, "SAVE", save_btn, 14, raylib.BLACK)
        raylib.DrawRectangleRec(settings_btn, raylib.RAYWHITE)
        draw_centered_text(font, "S", settings_btn, 24, raylib.BLACK)

        // Settings Modal
        if show_settings {
            raylib.DrawRectangle(0, 0, 400, 800, {0, 0, 0, 200})
            modal := raylib.Rectangle{50, 200, 300, 420}
            raylib.DrawRectangleRec(modal, {40, 40, 45, 255})
            raylib.DrawRectangleLinesEx(modal, 2, raylib.GOLD)
            
            if show_credits {
                draw_centered_text(font, "CREDITS", {50, 220, 300, 40}, 28, raylib.GOLD)
                draw_text(font, "CODE: YOU", 75, 280, 18, raylib.WHITE)
                draw_text(font, "ENGINE: ODIN + RAYLIB", 75, 310, 18, raylib.WHITE)
                draw_text(font, "FONT: RADIO STARS", 75, 340, 18, raylib.SKYBLUE)
                draw_text(font, "BY CHEQUERED INK", 75, 360, 12, raylib.LIGHTGRAY)
                draw_text(font, "UI: RETRO FUTURE", 75, 400, 18, raylib.WHITE)
                back_btn := raylib.Rectangle{70, 560, 260, 40}
                raylib.DrawRectangleRec(back_btn, raylib.GRAY)
                draw_centered_text(font, "BACK", back_btn, 18, raylib.BLACK)
            } else {
                draw_centered_text(font, "SETTINGS", {50, 220, 300, 40}, 28, raylib.GOLD)
                cred_btn := raylib.Rectangle{70, 440, 260, 50}
                raylib.DrawRectangleRec(cred_btn, raylib.DARKBLUE)
                draw_centered_text(font, "VIEW CREDITS", cred_btn, 20, raylib.WHITE)
                del_btn := raylib.Rectangle{70, 500, 260, 50}
                raylib.DrawRectangleRec(del_btn, raylib.MAROON)
                draw_centered_text(font, "DELETE SAVE", del_btn, 20, raylib.WHITE)
            }
        }

        // Particles
        for p in particles {
            alpha := u8(p.life * 255); c := p.color; c.a = alpha
            if p.text != "" do draw_text(font, p.text, i32(p.pos.x), i32(p.pos.y), 12 * p.life + 12, c)
            else do raylib.DrawRectanglePro({p.pos.x, p.pos.y, p.size, p.size}, {p.size/2, p.size/2}, p.life * 360, c)
        }
        raylib.EndDrawing()
    }
    
    save_game(aurum, ores, miners, factories, upgrades)
    delete(particles); raylib.UnloadFont(font); raylib.CloseWindow()
}