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
				float3 vertex : POSITION; // it's actually a ball's center position, not the actual vertex pos
				half3 normal : NORMAL; // actually, it's an offset from center allowing to restore the vertex pos
				fixed4 color : COLOR; // just some random color to make balls different
				float2 texcoord0 : TEXCOORD0; // just two randoms: for phase and speed variance
			};

			struct v2f {
				float4 vertex : SV_POSITION; // clip-space position
				fixed4 color : COLOR; // vertex color, as is
			};

			float _MinSpeed, _RndSpeed, _Height, _Radius, _Dive;
			
			
			// Given vertical ball scale, calculate the 3D scale to mimic
			// volume-preservation effect
			float3 shrinkScale(float vertScale) {
				vertScale = max(vertScale, 0.1);
				float invScale = pow(1.0 / vertScale, 0.3);
				return float3(invScale, vertScale, invScale);
			}
			
			// Transform (compensate offset/scale) the ball to mimic it's squashing
			// when it's pivot goes inder 0 in world space
			void squashBall(in float diam, inout float3 worldVertexOffset, inout float offsetY) {
				float dive = max(-offsetY, 0); // absolute in world: how much a ball is below 0
				offsetY += dive; // stick it back to the ground level
				float vertShrink = 1.0 - (dive / diam); // how much we need to squeeze the ball in Y
				worldVertexOffset *= shrinkScale(vertShrink);
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				// first, we need to transfrom all the vectors to world-space,
				// to perform any further modifications there:
				float3 worldPivot = mul(unity_ObjectToWorld, float4(v.vertex, 1.0));
				float3 worldVertexOffset = UnityObjectToWorldDir(v.normal) * _Radius + float3(0, _Radius, 0);
				
				float diam = _Radius * 2.0;
				float offsetY;
				{ // calc main ball movement (up-down, based on cos)
					float speed = max(_MinSpeed + _RndSpeed * v.texcoord0.y, 0.001);
					float cycleLen = 1.0 / speed;
					float progress = (_Time.y % cycleLen) * speed; // cycles in [0 to 1] range
					progress += v.texcoord0.x; // randomize phase offset for each ball.
					// progress can go beyond 1 now, but the random value
					// should also be in [0, 1] range, so in total progress is in [0, 2] anyway,
					// which precision is still enough for smooth movement
					offsetY = cos(progress * UNITY_TWO_PI) * 0.5 + 0.5;
					offsetY = pow(offsetY, 0.4) * _Height - _Dive * diam;
				}
				// the ball dives under ground: turn it to squashing:
				squashBall(diam, /* inout: */ worldVertexOffset, offsetY);
				
				float3 worldPos = worldPivot + worldVertexOffset;
				worldPos.y += offsetY;
				
				o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0)); // from world to clip space
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
