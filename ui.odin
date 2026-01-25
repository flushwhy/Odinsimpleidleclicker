package main

import "core:fmt"
import "core:strings"
import "core:math/rand"
import "vendor:raylib"

format_commas :: proc(val: f64) -> string {
    n := i64(val)
    if n == 0 do return "0"
    buf: [32]byte
    cursor := len(buf)
    abs_n := abs(n)
    for abs_n > 0 {
        if (len(buf) - cursor) > 0 && (len(buf) - cursor) % 4 == 3 {
            cursor -= 1
            buf[cursor] = ','
        }
        cursor -= 1
        buf[cursor] = '0' + byte(abs_n % 10)
        abs_n /= 10
    }
    return strings.clone(string(buf[cursor:]), context.temp_allocator)
}

draw_text :: proc(font: raylib.Font, text: string, x, y: i32, size: f32, color: raylib.Color) {
    pos := raylib.Vector2{f32(x), f32(y)}
    raylib.DrawTextEx(font, fmt.ctprintf("%s", text), pos, size, 1, color)
}

spawn_burst :: proc(particles: ^[dynamic]Particle, pos: raylib.Vector2, count: int, color: raylib.Color, speed: f32 = 200) {
    for _ in 0..=count {
        append(particles, Particle{
            pos = pos,
            vel = {rand.float32_range(-speed, speed), rand.float32_range(-speed, speed)},
            life = 1.0, color = color, size = rand.float32_range(2, 5),
        })
    }
}

draw_centered_text :: proc(font: raylib.Font, text: string, rect: raylib.Rectangle, size: f32, color: raylib.Color) {
    text_size := raylib.MeasureTextEx(font, raylib.TextFormat("%s", text), size, 1)
    
    pos := raylib.Vector2{
        rect.x + (rect.width / 2) - (text_size.x / 2),
        rect.y + (rect.height / 2) - (text_size.y / 2) + 2,
    }
    raylib.DrawTextEx(font, raylib.TextFormat("%s", text), pos, size, 1, color)
}