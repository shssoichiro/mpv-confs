//!PARAM allow_upscale
//!DESC Allow area upscaling (0 = downscale only [default], 1 = also upscale)
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 1
0

//!DESC Linear-light Area Scaler (Integer Coordinates)
//!HOOK MAIN
//!BIND HOOKED
//!WIDTH OUTPUT.w HOOKED.w < allow_upscale + ! ! OUTPUT.w HOOKED.w - * HOOKED.w +
//!HEIGHT OUTPUT.h HOOKED.h < allow_upscale + ! ! OUTPUT.h HOOKED.h - * HOOKED.h +
//!WHEN allow_upscale OUTPUT.w HOOKED.w = ! OUTPUT.h HOOKED.h = ! + * allow_upscale ! OUTPUT.w HOOKED.w < OUTPUT.h HOOKED.h < + * +


vec4 hook() {
    uvec2 src_size = uvec2(HOOKED_size);
    uvec2 target = uvec2(target_size);
    uvec2 dst_size = (allow_upscale > 0)
        ? target
        : min(src_size, target);

    uvec2 dst_coord =
        min(uvec2(HOOKED_pos * vec2(dst_size)), dst_size - 1u);

    uvec2 numerator = dst_coord * src_size;
    uvec2 remainder = numerator % dst_size;

    ivec2 first_src_pixel = ivec2(numerator / dst_size);

    vec2 box_size  = vec2(src_size) / vec2(dst_size);
    vec2 box_start = vec2(remainder) / vec2(dst_size);
    vec2 box_end   = box_start + box_size;

    uvec2 span = 1u + (remainder + src_size - 1u) / dst_size;
    ivec2 src_pixel_max = ivec2(src_size) - 1;

    vec4 accum = vec4(0.0);
    float total_weight = 0.0;

    for (int j = 0; j < int(span.y); ++j) {
        float overlap_y =
            min(box_end.y, float(j + 1)) -
            max(box_start.y, float(j));

        int sy = min(first_src_pixel.y + j, src_pixel_max.y);
        float sample_y = (float(sy) + 0.5) * HOOKED_pt.y;

        for (int i = 0; i < int(span.x); ++i) {
            float overlap_x =
                min(box_end.x, float(i + 1)) -
                max(box_start.x, float(i));

            float weight = overlap_x * overlap_y;

            int sx = min(first_src_pixel.x + i, src_pixel_max.x);

            vec2 sample_pos = vec2(
                (float(sx) + 0.5) * HOOKED_pt.x,
                sample_y
            );

            accum += weight * linearize(HOOKED_tex(sample_pos));
            total_weight += weight;
        }
    }

    return delinearize(accum / total_weight);
}