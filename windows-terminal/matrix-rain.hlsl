// Falling binary digits behind the terminal text, for Windows Terminal's
// experimental.pixelShaderPath. No textures or libraries needed.
// Tune RAIN_STRENGTH (0 to 1) to make the rain fainter or brighter.

Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings
{
    float time;
    float scale;
    float2 resolution;
    float4 background;
};

#define RAIN_STRENGTH 0.30
#define TRAIL_ROWS 18.0

float hash(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// One digit drawn inside a 0..1 cell: a bar for "1", a ring for "0".
float digit(float2 uv, float isOne)
{
    float2 c = uv - 0.5;
    float bar = step(abs(c.x), 0.07) * step(abs(c.y), 0.32);
    float d = length(c / float2(0.22, 0.34));
    float ring = step(0.72, d) * step(d, 1.0);
    return lerp(ring, bar, isOne);
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
    float4 color = shaderTexture.Sample(samplerState, tex);

    float2 px = tex * resolution;
    float2 cellSize = float2(10.0, 18.0) * scale;
    float2 cell = floor(px / cellSize);
    float2 uv = frac(px / cellSize);

    float rows = resolution.y / cellSize.y;
    float active = step(0.35, hash(float2(cell.x, 3.0)));
    float speed = 3.0 + hash(float2(cell.x, 5.0)) * 7.0;
    float offset = hash(float2(cell.x, 7.0)) * 200.0;
    float head = fmod(time * speed + offset, rows + TRAIL_ROWS);
    float dist = head - cell.y;
    float inTrail = step(0.0, dist) * step(dist, TRAIL_ROWS);
    float fade = 1.0 - dist / TRAIL_ROWS;
    float headBoost = 1.0 + step(dist, 1.0) * 1.5;

    float isOne = step(0.5, hash(cell + floor(time * 1.5 + cell.x)));
    float shape = digit(uv, isOne);

    float3 rain = float3(0.0, 1.0, 0.25) * shape * fade * headBoost * inTrail * active * RAIN_STRENGTH;

    // Only draw where the terminal itself is dark, so text stays crisp.
    float textMask = saturate(max(color.r, max(color.g, color.b)) * 4.0);
    color.rgb += rain * (1.0 - textMask);
    return color;
}
