Shader "MeshParticle"
{
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		_SpriteSize ("Size", Float) = 1.0
		
		[Space] [Header(Shader Blending)]
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 0
		[Enum(None,0,Alpha,1,RGB,14,RGBA,15)] _ColorMask ("out Color Mask", Float) = 15
		[Enum(Off, 0, On, 1)] _zWrite ("Z-Write", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _zTest ("Z-Test", Int) = 2
	}
	
	CGINCLUDE
		#pragma vertex vert
		#pragma fragment frag
		// make fog work
		#pragma multi_compile_fog

		#include "UnityCG.cginc"

		struct appdata
		{
			float3 vertex : POSITION;
			half2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			half2 uv : TEXCOORD0;
		};

		sampler2D _MainTex;
		float _SpriteSize;
		
		#define cameraWorldAxis_X unity_CameraToWorld._m00_m10_m20
		#define cameraWorldAxis_Y unity_CameraToWorld._m01_m11_m21
		#define cameraWorldAxis_Z unity_CameraToWorld._m02_m12_m22
		
		
		float3 worldSpriteOffsets(float3 worldPivot, float2 offsets2D)
		{
			// float3 mtxZ = normalize(UnityWorldSpaceViewDir(worldPivot));
			float3 mtxX = normalize(cameraWorldAxis_X);
			float3 mtxY = normalize(cameraWorldAxis_Y);
			
			float3 worldOffset = offsets2D.xxx * mtxX + offsets2D.yyy * mtxY;
			return worldOffset * _SpriteSize;
		}

		v2f vert (appdata v)
		{
			v2f o;
			// float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex, 1.0));
			float3 worldPos = 0;
			float2 offsets2D = v.uv * 2 - 1;
			
			worldPos += worldSpriteOffsets(worldPos, offsets2D);
			// TODO
			o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0)); // from world to clip space
			o.uv = v.uv;
			return o;
		}

		fixed4 frag (v2f i) : SV_Target
		{
			// sample the texture
			fixed4 col = tex2D(_MainTex, i.uv);
			return col;
		}
	ENDCG
	
	Category {
		Tags {
			"PreviewType"="Plane"
			"Queue"="Transparent"
			"RenderType"="Transparent"
			"IgnoreProjector"="True"
			"ForceNoShadowCasting"="True"
		}
		
		Blend One OneMinusSrcAlpha
		ColorMask [_ColorMask]
		Cull [_Cull]
		ZTest [_zTest]
		ZWrite [_zWrite]
		Lighting Off
		
		SubShader { Pass {
			CGPROGRAM
			#pragma target 3.0
			ENDCG
		} }
		SubShader { Pass {
			CGPROGRAM
			// default render qwueue - 2.5
			ENDCG
		} }
		SubShader { Pass {
			CGPROGRAM
			#pragma target 2.0
			ENDCG
		} }
	}
	
}
