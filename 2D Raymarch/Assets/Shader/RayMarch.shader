Shader "Unlit/RayMarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float Distance(float2 xy1, float2 xy2){
                return sqrt((xy1.x - xy2.x) * (xy1.x - xy2.x) + (xy1.y - xy2.y) * (xy1.y - xy2.y));
            }

            bool Mandelbrot(float2 xy){

                float bail = 2;
                float2 z = float2(0,0);
                int i;
                for(i = 0; i < 25; i++){
                    float a = z.x * z.x - z.y * z.y;
                    float b = 2 * z.x * z.y;
                    z.x = a;
                    z.y = b;
                    z += xy;
                    if(sqrt(z.x*z.x+z.y*z.y) > bail){
                        return false;
                    }
                }
                return true;
            }

            bool Circle(float2 uv, float2 xy, float radius, float thickness){
                return Distance(uv,xy) > radius - thickness/2 && Distance(uv,xy) < radius + thickness/2;
            }

            float GetDist(float2 p){
                return length(p) - 100;
            }

            bool Line(float2 pos, float2 start, float2 rd, float distance){
                float2 x1 = start + rd * distance;
                if (Distance(start, x1) == Distance(start,pos) + Distance(pos,x1)){
                    return Circle(pos, pos, 0, 100);
                }else{
                    return false;
                }
            }

            float2 Raymarch(float2 ro, float2 rd) { // ray origin, ray direction
                float dO = 0; // distance origin
                float dS; // distance surface
                float i; // needed steps
                int maxSteps = 30;
                for (i = 0; i < maxSteps; i++) { // march until max steps reached
                    float2 p = ro + dO * rd; // position
                    dS = GetDist(p); // distance we can go without intersecting
                    if (dO + dS == dO) break;
                    dO += dS; // marching
                    if (dS < pow(10, -4) || dO > 2000) break; // hit surface or max distance reached
                }
                return float2(dO, i); // (distance, steps)
            }

            float4 Draw(float2 coord){
                float4 col = 0;

                if(Circle(coord, float2(0, 0), 100, 3)){
                    col.x = 1;
                }

                float2 a = Raymarch(float2(-500, -500), normalize(float2(1,1)));


                if(Circle(coord, float2(-500, -500), a, 3) || Circle(coord, float2(-500, -500), 0, 6) || Line( coord, float2(-500,-500), normalize(float2(1,1)), a)){
                    col = 1;
                }
                
                return col;

            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;
                float2 coord = i.uv * 2000;
                coord -= 1000;

                col = Draw(coord);

                return col;
            }
            ENDCG
        }
    }
}