#include <metal_stdlib>
using namespace metal;

struct MatchParameters {
    uint imageWidth;
    uint templateWidth;
    uint templateHeight;
    uint outputWidth;
    float templateMean;
    float templateSumSquaredDeviations;
};

kernel void normalizedCrossCorrelation(
    device const float *image [[buffer(0)]],
    device const float *templateImage [[buffer(1)]],
    device float *scores [[buffer(2)]],
    constant MatchParameters &parameters [[buffer(3)]],
    uint index [[thread_position_in_grid]]
) {
    const uint x = index % parameters.outputWidth;
    const uint y = index / parameters.outputWidth;
    const uint templateArea = parameters.templateWidth * parameters.templateHeight;

    float imageSum = 0.0f;
    for (uint templateY = 0; templateY < parameters.templateHeight; ++templateY) {
        const uint imageOffset = (y + templateY) * parameters.imageWidth + x;
        for (uint templateX = 0; templateX < parameters.templateWidth; ++templateX) {
            imageSum += image[imageOffset + templateX];
        }
    }

    const float imageMean = imageSum / float(templateArea);
    float numerator = 0.0f;
    float imageSumSquaredDeviations = 0.0f;

    for (uint templateY = 0; templateY < parameters.templateHeight; ++templateY) {
        const uint imageOffset = (y + templateY) * parameters.imageWidth + x;
        const uint templateOffset = templateY * parameters.templateWidth;

        for (uint templateX = 0; templateX < parameters.templateWidth; ++templateX) {
            const float imageDeviation = image[imageOffset + templateX] - imageMean;
            const float templateDeviation =
                templateImage[templateOffset + templateX] - parameters.templateMean;
            numerator += imageDeviation * templateDeviation;
            imageSumSquaredDeviations += imageDeviation * imageDeviation;
        }
    }

    const float denominator = sqrt(
        imageSumSquaredDeviations * parameters.templateSumSquaredDeviations
    );
    scores[index] = denominator > 1.0e-12f ? clamp(numerator / denominator, -1.0f, 1.0f) : -1.0f;
}
