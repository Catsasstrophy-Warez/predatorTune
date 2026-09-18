// PredatorLab/Rendering/Metal/TelemetryWaveform.metal
// Line-strip renderer for a single telemetry channel trace.

#include <metal_stdlib>
using namespace metal;

struct WaveformVertexIn {
    float2 position [[attribute(0)]];
};

struct WaveformVertexOut {
    float4 position [[position]];
    float intensity;
};

struct WaveformUniforms {
    float4 lineColor;
    float2 viewportSize;
};

vertex WaveformVertexOut telemetry_waveform_vertex(
    const device float2 *positions [[buffer(0)]],
    constant WaveformUniforms &uniforms [[buffer(1)]],
    uint vertexID [[vertex_id]]
) {
    float2 sample = positions[vertexID];

    // sample.x, sample.y already arrive normalized to -1...1 clip space.
    WaveformVertexOut out;
    out.position = float4(sample.x, sample.y, 0.0, 1.0);
    out.intensity = clamp((sample.y + 1.0) * 0.5, 0.0, 1.0);
    return out;
}

fragment float4 telemetry_waveform_fragment(
    WaveformVertexOut in [[stage_in]],
    constant WaveformUniforms &uniforms [[buffer(1)]]
) {
    float3 base = uniforms.lineColor.rgb;
    float3 glow = mix(base * 0.6, base, in.intensity);
    return float4(glow, uniforms.lineColor.a);
}
