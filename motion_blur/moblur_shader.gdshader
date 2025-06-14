shader_type spatial;
render_mode depth_test_disabled, depth_draw_never, unshaded, cull_disabled;

uniform vec3 linear_velocity;
uniform vec3 angular_velocity;
uniform int samples : hint_range(4, 32) = 12;
uniform float shutter_speed = 0.5;
uniform float max_blur_pixels = 16.0;
uniform float depth_threshold = 0.1; // New: prevents edge bleeding

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// Helper function for safe texture sampling
vec3 safe_sample(vec2 uv) {
    uv = clamp(uv, vec2(0.001), vec2(0.999)); // Keep within bounds
    return textureLod(SCREEN_TEXTURE, uv, 0.0).rgb;
}

void fragment() {
    // 1. Get current pixel's depth and world position
    float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0);
    vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view_pos.xyz /= view_pos.w;
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(view_pos.xyz, 1.0)).xyz;
    
    // 2. Calculate velocity at this position
    vec3 cam_pos = INV_VIEW_MATRIX[3].xyz;
    vec3 r = world_pos - cam_pos;
    vec3 world_velocity = linear_velocity + cross(angular_velocity, r);
    
    // 3. Get previous position and screen velocity
    vec4 prev_pos = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world_pos - world_velocity * shutter_speed, 1.0);
    prev_pos.xy /= prev_pos.w;
    vec2 screen_velocity = (ndc.xy - prev_pos.xy) * 0.5;
    
    // 4. Clamp velocity and check if we should blur
    float blur_length = length(screen_velocity) * VIEWPORT_SIZE.x;
    if (blur_length > max_blur_pixels) {
        screen_velocity *= max_blur_pixels / blur_length;
        blur_length = max_blur_pixels;
    }
    
    // 5. Edge-aware motion blur
    vec3 color = safe_sample(SCREEN_UV);
    if (blur_length > 0.5) {
        float center_depth = depth;
        float valid_samples = 1.0;
        
        for (int i = 1; i < samples; ++i) {
            float t = float(i) / float(samples - 1) - 0.5;
            vec2 offset = screen_velocity * t;
            vec2 sample_uv = SCREEN_UV + offset;
            
            // Check if sample is valid
            float sample_depth = texture(DEPTH_TEXTURE, sample_uv).r;
            if (abs(sample_depth - center_depth) < depth_threshold) {
                color += safe_sample(sample_uv);
                valid_samples += 1.0;
            }
        }
        color /= valid_samples;
    }
    
    ALBEDO = color;
}