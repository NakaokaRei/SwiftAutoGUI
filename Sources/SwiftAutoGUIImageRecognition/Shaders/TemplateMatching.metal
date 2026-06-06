#include <metal_stdlib>
using namespace metal;

struct MatchParameters {
    uint imageWidth;
    uint imageHeight;
    uint templateWidth;
    uint templateHeight;
    uint outputWidth;
    uint outputHeight;
    float templateMean;
    float templateSumSquaredDeviations;
};

inline float normalizedScore(
    float imageSum,
    float imageSumOfSquares,
    float crossSum,
    constant MatchParameters &parameters
) {
    const float templateArea = float(parameters.templateWidth * parameters.templateHeight);
    const float numerator = crossSum - parameters.templateMean * imageSum;
    const float imageSumSquaredDeviations = max(
        imageSumOfSquares - imageSum * imageSum / templateArea,
        0.0f
    );
    const float denominator = sqrt(
        imageSumSquaredDeviations * parameters.templateSumSquaredDeviations
    );
    return denominator > 1.0e-12f
        ? clamp(numerator / denominator, -1.0f, 1.0f)
        : -1.0f;
}

kernel void normalizedCrossCorrelation(
    device const uchar *image [[buffer(0)]],
    device const uchar *templateImage [[buffer(1)]],
    device float *scores [[buffer(2)]],
    constant MatchParameters &parameters [[buffer(3)]],
    uint2 position [[thread_position_in_grid]]
) {
    if (position.x >= parameters.outputWidth || position.y >= parameters.outputHeight) {
        return;
    }

    float imageSum = 0.0f;
    float imageSumOfSquares = 0.0f;
    float crossSum = 0.0f;
    constexpr float scale = 1.0f / 255.0f;

    for (uint templateY = 0; templateY < parameters.templateHeight; ++templateY) {
        const uint imageOffset =
            (position.y + templateY) * parameters.imageWidth + position.x;
        const uint templateOffset = templateY * parameters.templateWidth;

        for (uint templateX = 0; templateX < parameters.templateWidth; ++templateX) {
            const float imageValue = float(image[imageOffset + templateX]) * scale;
            const float templateValue = float(templateImage[templateOffset + templateX]) * scale;
            imageSum += imageValue;
            imageSumOfSquares += imageValue * imageValue;
            crossSum += imageValue * templateValue;
        }
    }

    const uint index = position.y * parameters.outputWidth + position.x;
    scores[index] = normalizedScore(
        imageSum,
        imageSumOfSquares,
        crossSum,
        parameters
    );
}

kernel void tiledNormalizedCrossCorrelation(
    device const uchar *image [[buffer(0)]],
    device const uchar *templateImage [[buffer(1)]],
    device float *scores [[buffer(2)]],
    constant MatchParameters &parameters [[buffer(3)]],
    threadgroup uchar *imageTile [[threadgroup(0)]],
    uint2 threadgroupPosition [[threadgroup_position_in_grid]],
    uint2 threadPosition [[thread_position_in_threadgroup]],
    uint2 threadsPerThreadgroup [[threads_per_threadgroup]]
) {
    const uint tileWidth = parameters.templateWidth + threadsPerThreadgroup.x - 1;
    const uint tileHeight = parameters.templateHeight + threadsPerThreadgroup.y - 1;
    const uint tileCount = tileWidth * tileHeight;
    const uint threadIndex =
        threadPosition.y * threadsPerThreadgroup.x + threadPosition.x;
    const uint threadCount = threadsPerThreadgroup.x * threadsPerThreadgroup.y;
    const uint2 groupOrigin = threadgroupPosition * threadsPerThreadgroup;

    for (uint tileIndex = threadIndex; tileIndex < tileCount; tileIndex += threadCount) {
        const uint tileX = tileIndex % tileWidth;
        const uint tileY = tileIndex / tileWidth;
        const uint imageX = groupOrigin.x + tileX;
        const uint imageY = groupOrigin.y + tileY;
        imageTile[tileIndex] =
            imageX < parameters.imageWidth && imageY < parameters.imageHeight
            ? image[imageY * parameters.imageWidth + imageX]
            : 0;
    }
    threadgroup_barrier(mem_flags::mem_threadgroup);

    const uint2 position = groupOrigin + threadPosition;
    if (position.x >= parameters.outputWidth || position.y >= parameters.outputHeight) {
        return;
    }

    float imageSum = 0.0f;
    float imageSumOfSquares = 0.0f;
    float crossSum = 0.0f;
    constexpr float scale = 1.0f / 255.0f;

    for (uint templateY = 0; templateY < parameters.templateHeight; ++templateY) {
        const uint imageOffset =
            (threadPosition.y + templateY) * tileWidth + threadPosition.x;
        const uint templateOffset = templateY * parameters.templateWidth;

        for (uint templateX = 0; templateX < parameters.templateWidth; ++templateX) {
            const float imageValue = float(imageTile[imageOffset + templateX]) * scale;
            const float templateValue = float(templateImage[templateOffset + templateX]) * scale;
            imageSum += imageValue;
            imageSumOfSquares += imageValue * imageValue;
            crossSum += imageValue * templateValue;
        }
    }

    const uint index = position.y * parameters.outputWidth + position.x;
    scores[index] = normalizedScore(
        imageSum,
        imageSumOfSquares,
        crossSum,
        parameters
    );
}
