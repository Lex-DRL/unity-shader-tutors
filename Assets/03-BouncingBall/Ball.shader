Shader "Unlit/Ball"
{
	Properties {
		[Header(UV x is phase offset)]
		[Header(UV y is speed random)]
		_MinSpeed ("Min Speed", Float) = 0.5
		_RndSpeed ("Random Speed", Float) = 1.0
		_Height ("Height", Float) = 1.0
		_Radius ("Radius", Range(0.001, 2)) = 1.0
		_Dive ("Dive", Range(0, 0.9)) = 0.5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata {
				float3 vertex : POSITION;
				half3 normal : NORMAL;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
			};

			float _MinSpeed, _RndSpeed, _Height, _Radius, _Dive;
			
			
			float3 shrinkScale(float vertScale) {
				vertScale = max(vertScale, 0.1);
				float invScale = pow(1.0 / vertScale, 0.3);
				return float3(invScale, vertScale, invScale);
			}
			
			void squashBall(in float diam, inout float3 worldOffset, inout float offsetY) {
				float dive = max(-offsetY, 0); // absolute in world
				offsetY += dive;
				float vertShrink = 1.0 - (dive / diam); // relative to ball size
				worldOffset *= shrinkScale(vertShrink);
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				float3 worldPivot = mul(unity_ObjectToWorld, float4(v.vertex, 1.0));
				float3 worldOffset = UnityObjectToWorldDir(v.normal) * _Radius + float3(0, _Radius, 0);
				
				float diam = _Radius * 2.0;
				float offsetY;
				{ // calc main trajectory
					float speed = max(_MinSpeed + _RndSpeed * v.texcoord.y, 0.001);
					float cycleLen = 1.0 / speed;
					float progress = (_Time.y % cycleLen) * speed; // animates from 0 to 1
					progress += v.texcoord.x;
					offsetY = cos(progress * UNITY_TWO_PI) * 0.5 + 0.5;
					offsetY = pow(offsetY, 0.4) * _Height - _Dive * diam;
				}
				// the ball dives under ground and bounces up
				squashBall(diam, /* inout: */ worldOffset, offsetY);
				
				float3 worldPos = worldPivot + worldOffset;
				worldPos.y += offsetY;
				
				o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
				o.color = v.color;
				return o;
			}
			
			// GPU work

			fixed4 frag (v2f i) : SV_Target
			{
				return i.color;
			}
			ENDCG
		}
	}
}
