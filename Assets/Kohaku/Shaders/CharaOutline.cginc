// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Outline shader

// Editable parameters

// Material color
float4 _Color;

// Light color
float4 _LightColor0;

// Outline thickness
float _EdgeThickness = 1.0;

// Depth bias to help prevent z-fighting
float _DepthBias = 0.00012;

float4 _MainTex_ST;

// Main texture
sampler2D _MainTex;

struct v2f
{
    float4 pos : SV_POSITION;
    float2 UV : TEXCOORD0;
};

// Float types
#define float_t  half
#define float2_t half2
#define float3_t half3
#define float4_t half4

// Amount to scale the distance from the camera into a value to scale the outline by. Tweak as desired
#define OUTLINE_DISTANCE_SCALE (0.0016)
// Minimum and maximum outline thicknesses (Before multiplying by _EdgeThickness)
#define OUTLINE_NORMAL_SCALE_MIN (0.003)
#define OUTLINE_NORMAL_SCALE_MAX (0.030)

// Vertex shader
v2f vert(appdata_base v)
{
    float4 projPos = UnityObjectToClipPos(v.vertex);
    float4 projNormal = normalize(UnityObjectToClipPos(float4(v.normal, 0)));

    float distanceToCamera = OUTLINE_DISTANCE_SCALE * projPos.z;
    float normalScale = _EdgeThickness *
        lerp(OUTLINE_NORMAL_SCALE_MIN, OUTLINE_NORMAL_SCALE_MAX, distanceToCamera);

    v2f o;
    o.pos = projPos + normalScale * projNormal;
    o.pos.z += _DepthBias;
    o.UV = v.texcoord.xy;

    return o;
}

// Get the maximum component of a 3-component color
inline float_t GetMaxComponent(float3_t inColor)
{
    return max(max(inColor.r, inColor.g), inColor.b);
}

// Function to fake setting the saturation of a color. Not a true HSL computation.
inline float3_t SetSaturation(float3_t inColor, float_t inSaturation)
{
    // Compute the saturated color to be one where all components smaller than the max are set to 0.
    // Note that this is just an approximation.
    float_t maxComponent = GetMaxComponent(inColor) - 0.0001;
    float3_t saturatedColor = step(maxComponent.rrr, inColor) * inColor;
    return lerp(inColor, saturatedColor, inSaturation);
}

// Outline color parameters. Tweak as desired
#define SATURATION_FACTOR 0.6
#define BRIGHTNESS_FACTOR 0.8

// Fragment shader
float4_t frag(v2f i) : COLOR
{
    float4_t mainMapColor = tex2D(_MainTex, i.UV);

    float3_t outlineColor = BRIGHTNESS_FACTOR
        * SetSaturation(mainMapColor.rgb, SATURATION_FACTOR)
        * mainMapColor.rgb;

    return float4_t(outlineColor, mainMapColor.a) * _Color * _LightColor0;
}
