Shader "Custom/Dissolve" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0

		_DissolvePoint("Dissolve point", Vector) = (0,0,0,0)
		_DissolveAmount("Disolve amount", Range(0,1)) = 1
		_MaxDistance("Max distance", float) = 1
		_Intensity("Intensity", Range(1,5)) = 1
		_NoiseFreq("Noise frequency", float) = 1
		_Border("Border size", float) = 0.1
		_BorderColor("Border color", Color) = (1,0,0,1)
		_BorderEmission("Border emission", Color) = (1,0,0,1)
		[Toggle]_Inverse("Inverse", float) = 0
	}
	SubShader {
		Tags {
			"RenderType"="TransparentCutout"
			"Queue"="AlphaTest"
		}
		Cull Off
		
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard fullforwardshadows addshadow
		#include "UnityCG.cginc"
		#include "noiseSimplex.cginc"

		sampler2D _MainTex;
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		fixed _NoiseFreq;
		fixed _Border;
		fixed _Inverse;
		fixed4 _BorderColor;
		fixed4 _BorderEmission;

		uniform fixed _DissolveAmount;
		uniform fixed _MaxDistance;
		uniform fixed _Intensity;
		uniform float3 _DissolvePoint;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
		};

		void surf (Input IN, inout SurfaceOutputStandard o) {

			// texture and color
			fixed4 color = tex2D(_MainTex, IN.uv_MainTex) * _Color;

			// calculate distance between current position and dissolve point
			float dist = distance(IN.worldPos, _DissolvePoint);

			// get gradient by distance
			float gradient = clamp(dist / _MaxDistance, 0, 2);

			// calculate final value
			float finalValue = (_DissolveAmount - gradient) * _Intensity;

			// Inverse
			finalValue = lerp(finalValue, 1 - finalValue, _Inverse);

			// snoise is expensive
			// do not call it if we are sure the final value is large enough
			if (finalValue > _Border + 1) {
				discard;
			}

			// get noise by world position, snoise return -1~1
			// make the noise 0~1
			float ns = snoise(IN.worldPos * _NoiseFreq) / 2 + 0.5f;

			if (ns + _Border < finalValue) {
				discard;
			}

			// after clip, ns should be finalValue ~ (finalValue - _Border)
			// if (finalValue >= ns)
			//		isBorder
			// else
			//		!isBorder
			fixed isBorder = step(ns, finalValue);
			
			o.Albedo = lerp(color, _BorderColor, isBorder);
			o.Emission = lerp(fixed4(0, 0, 0, 0), _BorderEmission, isBorder);

			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
		}

		ENDCG
	}
	FallBack "Diffuse"
}
