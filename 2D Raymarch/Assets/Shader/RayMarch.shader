Shader "RayMarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Texture", 2D) = "white" {}
        _Dynamic ("Position / Direction", Vector) = (0,0,0,1)
    }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert alpha
            #pragma fragment frag alpha
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
            float4 _NoiseTex;
            float4 _Dynamic;

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

            float GetDistCircle(float2 pos, float2 cPos, float radius){
                return length(pos - cPos) - radius;
            }

            bool Circle(float2 uv, float2 xy, float radius, float thickness){
                return Distance(xy,uv) > radius - thickness && Distance(xy,uv) < radius;
            }

            float GetDistLine(float2 pos, float2 start, float2 end){
                float px = end.x - start.x;
                float py = end.y - start.y;
                float norm = px*px + py*py;
                float u = ((pos.x - start.x) * px + (pos.y - start.y) * py) / norm;

                if (u > 1) u = 1;
                else if (u < 0) u = 0;

                float x = start.x + u * px;
                float y = start.y + u * py;
                float dx = x - pos.x;
                float dy = y - pos.y;

                return pow(dx*dx + dy*dy,0.5);
            }

            bool Line(float2 pos, float2 start, float2 rd, float distance){
                float2 end = start + rd * distance;
                
                float dist = GetDistLine(pos, start, end);

                if (dist < 3){
                    return true;
                }
                return false;
            }

            bool Line(float2 pos, float2 start, float2 rd, float distance, float thickness){
                float2 end = start + rd * distance;
                
                float dist = GetDistLine(pos, start, end);

                if (dist < thickness){
                    return true;
                }
                return false;
            }

            bool Line(float2 pos, float2 start, float2 end){
                if (GetDistLine(pos, start, end) < 3) return true;
                return false;
            }

            float GetDist(float2 ro){
                // 16:9
                float smallest = GetDistLine(ro, float2(-1600,-900), float2(-1600,900));
                smallest = min( smallest, GetDistLine(ro, float2(-1600,-900), float2(1600,-900)) );
                smallest = min( smallest, GetDistLine(ro, float2(1600,900), float2(-1600,900)) );
                smallest = min( smallest, GetDistLine(ro, float2(1600,900), float2(1600,-900)) );

                // square
                /*
                float smallest = GetDistLine(ro, float2(-900,-900), float2(-900,900));
                smallest = min( smallest, GetDistLine(ro, float2(-900,-900), float2(900,-900)) );
                smallest = min( smallest, GetDistLine(ro, float2(900,900), float2(-900,900)) );
                smallest = min( smallest, GetDistLine(ro, float2(900,900), float2(900,-900)) );
                */


                // circles
                ///*
                smallest = min( smallest, GetDistCircle(ro, float2(900,200), 300) );
                smallest = min( smallest, GetDistCircle(ro, float2(-300,-500), 200) );
                smallest = min( smallest, GetDistCircle(ro, float2(-900,-200), 400) );
                smallest = min( smallest, GetDistCircle(ro, float2(-100,600), 200) );
                smallest = min( smallest, GetDistCircle(ro, float2(200,-200), 100) );
                //*/
                return smallest;
            }

            float2 ClosestPointOnLine(float2 pos, float2 start, float2 end){
                float px = end.x - start.x;
                float py = end.y - start.y;
                float norm = px*px + py*py;
                float u = ((pos.x - start.x) * px + (pos.y - start.y) * py) / norm;

                if (u > 1) u = 1;
                else if (u < 0) u = 0;

                float x = start.x + u * px;
                float y = start.y + u * py;
                float dx = x - pos.x;
                float dy = y - pos.y;
                return float2(dx,dy);
            }

            float2 ClosestPointOnCircle(float pos, float2 centre, float radius){
                //float2 dir = normalize(pos - centre);
                //return float2(centre + dir * radius);
                return centre;
            }

            // refactor!
            float2 GetGravityCentrePosition(float2 ro){
                // 16:9
                float smallest = GetDistLine(ro, float2(-1600,-900), float2(-1600,900));
                float2 pos = ClosestPointOnLine(ro, float2(-1600,-900), float2(-1600,900));

                float check = GetDistLine(ro, float2(-1600,-900), float2(1600,-900));
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnLine(ro, float2(-1600,-900), float2(1600,-900));
                }

                check = GetDistLine(ro, float2(1600,900), float2(-1600,900));
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnLine(ro, float2(1600,900), float2(-1600,900));
                }

                check = GetDistLine(ro, float2(1600,900), float2(1600,-900));
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnLine(ro, float2(1600,900), float2(1600,-900));
                }

                // square
                /*
                float smallest = GetDistLine(ro, float2(-900,-900), float2(-900,900));
                float2 pos = ClosestPointOnLine(ro, float2(-900,-900), float2(-900,900));

                float check = GetDistLine(ro, float2(-900,-900), float2(900,-900));
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnLine(ro, float2(-900,-900), float2(900,-900));
                }

                check = GetDistLine(ro, float2(900,900), float2(-900,900));
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnLine(ro, float2(900,900), float2(-900,900));
                }

                check = GetDistLine(ro, float2(900,900), float2(900,-900));
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnLine(ro, float2(900,900), float2(900,-900));
                }
                */

                //float2 pos = float2(0,0);
                //float check = GetDistCircle(ro, float2(900,200), 300);
                ///*
                check = GetDistCircle(ro, float2(900,200), 300);
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnCircle(ro, float2(900,200), 300);
                }

                check = GetDistCircle(ro, float2(-300,-500), 200);
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnCircle(ro, float2(-300,-500), 200);
                }

                check = GetDistCircle(ro, float2(-900,-200), 400);
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnCircle(ro, float2(-900,-200), 400);
                }
                
                check = GetDistCircle(ro, float2(-100,600), 200);
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnCircle(ro, float2(-100,600), 200);
                }
                
                check = GetDistCircle(ro, float2(200,-200), 100);
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnCircle(ro, float2(200,-200), 100);
                }
                //*/
                return pos;
            }

            float2 GetNormal(float2 p) {
                float2 e = float2(0.125, 0);
                float2 n = GetDist(p) - float2(
                    GetDist(p - e.xy),
                    GetDist(p - e.yx)
                );
                return normalize(n);
            }

            float3 HueShift (float3 color, float shift){
                float3 p = float3(0.55735,0.55735,0.55735) * dot(float3(0.55735,0.55735,0.55735), color);
                float3 u = color-p;
                float3 v = cross(float3(0.55735,0.55735,0.55735),u);
                color = u*cos(shift*6.2832) + v*sin(shift*6.2832) + p;
                //color.x = floor(color.x * 16 + 0.5) / 16;
                //color.y = floor(color.y * 16 + 0.5) / 16;
                //color.z = floor(color.z * 16 + 0.5) / 16;
                //color = normalize(color);
                return color;
            }








            inline float unity_noise_randomValue (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            inline float unity_noise_interpolate (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }

            inline float unity_valueNoise (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            float Unity_SimpleNoise_float(float2 UV, float Scale)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                return t;
            }

            float Noise(float2 coord, float scale){
                return Unity_SimpleNoise_float(float2((coord.x+900)/1800,(coord.y+1600)/3200), scale);
            }








            float4 Draw(float2 coord){
                float4 col = 0;

                float speed = 100;

                if(Circle(coord, float2(0, 0), 0, 3))col = 1;

                // if(Circle(coord, float2(900, 200), 300, 20)) col.x = 1;
                // if(Circle(coord, float2(-300, -500), 200, 20)) col.x = 1;
                // if(Circle(coord, float2(-900,-200), 400, 20)) col.x = 1;
                // if(Circle(coord, float2(-100,600), 200, 20)) col.x = 1;
                // if(Circle(coord, float2(200,-200), 100, 20)) col.x = 1;
                
                //float2 ro = _Dynamic.xy;
                //float2 rd = _Dynamic.zw;
                //float2 ro = float2(-sin(_Time.x * speed) * 100, -cos(_Time.x * speed) * 100);
                float2 ro = float2(0,0);
                float2 rd = normalize(float2(sin(_Time.x * speed), cos(_Time.x * speed)));

                float2 newOrigin = ro;
                float newDist = GetDist(newOrigin) / 5;
                float totalReflections = 1;
                for (int reflection = 0; reflection < totalReflections; reflection++){
                    float totalDist = 0;
                    for (int steps = 0; steps < 1000; steps++){
                        //if(reflection > 0){
                            //if(Line( coord, newOrigin, rd, newDist, 4)) col.xyz = float3(0,0,0);
                            //if(Line( coord, newOrigin, rd, newDist, 3.02)) col.xyz = float3(1,1,1);
                            if(Line( coord, newOrigin, rd, newDist, 3 )){
                                col.xyz = HueShift(float3(1,0.5,0.6) , _Time.x*0.1593 * speed);// Time.x * 0.1593 -> Hue Full circle
                                col *= 1 - Noise(coord,(float)steps);
                            } 

                        //}
                        //if(Circle(coord, newOrigin, newDist, 20)) col.z = 1 - (float)reflection/6;
                        //if(Circle(coord, newOrigin, 5/newDist, 5/newDist)) col = 1;

                        newOrigin = newOrigin + newDist * rd;
                        rd = normalize( rd - normalize(GetGravityCentrePosition(newOrigin) - newOrigin) * -0.005 );//1/GetDist(newOrigin));
                        newDist = GetDist(newOrigin) / 5;
                        
                        
                        totalDist = totalDist + newDist;

                        if(newDist < 1){
                            if(Circle(coord, newOrigin, 0, 3)) col = 0;

                            float2 normal = GetNormal(newOrigin);

                            newOrigin = newOrigin - 1.5 * rd;

                            rd = rd - 2 * dot(normal, rd) * normal;
                            ro = newOrigin;
                            break;
                        }
                        
                    }
                }

                if (col.x == 0 && col.y == 0 && col.z == 0){
                    discard;
                }
                return col;

            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;
                float2 coord = i.uv * 200;
                coord -= 100;
                coord.x = coord.x * 16;
                coord.y = coord.y * 9;

                col = Draw(coord);
                
                return col;
            }
            ENDCG
        }
    }
}