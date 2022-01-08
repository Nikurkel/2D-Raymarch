using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class BounceShader : MonoBehaviour
{

    [SerializeField] Material shaderMat;
    [SerializeField] float delay;
    [SerializeField] Image img;

    private Texture2D texture;
    private Vector2 startPos;
    private Vector2 dir;

    private Color[] c;



    void Awake(){
        texture = new Texture2D(640, 360);
        img.material.mainTexture = texture;
        
        c = new Color[texture.width * texture.height];

        startPos = new Vector2(0,0);
        dir = new Vector2(0,1);
    }

    float GetDistLine(Vector2 pos, Vector2 start, Vector2 end){
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

        return Mathf.Pow(dx*dx + dy*dy,0.5f);
    }

    float GetDistCircle(Vector2 pos, Vector2 cPos, float radius){
        return (pos - cPos).magnitude - radius;
    }

    float GetDist(Vector2 ro){
        float smallest = GetDistLine(ro, new Vector2(-1600,-900), new Vector2(-1600,900));
        smallest = Mathf.Min( smallest, GetDistLine(ro, new Vector2(-1600,-900), new Vector2(1600,-900)) );
        smallest = Mathf.Min( smallest, GetDistLine(ro, new Vector2(1600,900), new Vector2(-1600,900)) );
        smallest = Mathf.Min( smallest, GetDistLine(ro, new Vector2(1600,900), new Vector2(1600,-900)) );

        smallest = Mathf.Min( smallest, GetDistCircle(ro, new Vector2(900,200), 300) );
        smallest = Mathf.Min( smallest, GetDistCircle(ro, new Vector2(-300,-500), 200) );
        smallest = Mathf.Min( smallest, GetDistCircle(ro, new Vector2(-900,-200), 400) );
        smallest = Mathf.Min( smallest, GetDistCircle(ro, new Vector2(-100,600), 200) );
        smallest = Mathf.Min( smallest, GetDistCircle(ro, new Vector2(200,-200), 100) );
        return smallest;
    }

    Vector2 ClosestPointOnLine(Vector2 pos, Vector2 start, Vector2 end){
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
        return new Vector2(dx,dy);
    }

    Vector2 GetGravityCentrePosition(Vector2 ro){
                float smallest = GetDistLine(ro, new Vector2(-1600,-900), new Vector2(-1600,900));
                Vector2 pos = ClosestPointOnLine(ro, new Vector2(-1600,-900), new Vector2(-1600,900));

                float check = GetDistLine(ro, new Vector2(-1600,-900), new Vector2(1600,-900));
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnLine(ro, new Vector2(-1600,-900), new Vector2(1600,-900));
                }

                check = GetDistLine(ro, new Vector2(1600,900), new Vector2(-1600,900));
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnLine(ro, new Vector2(1600,900), new Vector2(-1600,900));
                }

                check = GetDistLine(ro, new Vector2(1600,900), new Vector2(1600,-900));
                if(check < smallest){
                    smallest = check;
                    pos = ClosestPointOnLine(ro, new Vector2(1600,900), new Vector2(1600,-900));
                }


                check = GetDistCircle(ro, new Vector2(900,200), 300);
                if(check < smallest){
                    smallest = check;
                    pos = new Vector2(900,200);
                }

                check = GetDistCircle(ro, new Vector2(-300,-500), 200);
                if(check < smallest){
                    smallest = check;
                    pos = new Vector2(-300,-500);
                }

                check = GetDistCircle(ro, new Vector2(-900,-200), 400);
                if(check < smallest){
                    smallest = check;
                    pos = new Vector2(-900,-200);
                }
                
                check = GetDistCircle(ro, new Vector2(-100,600), 200);
                if(check < smallest){
                    smallest = check;
                    pos = new Vector2(-100,600);
                }
                
                check = GetDistCircle(ro, new Vector2(200,-200), 100);
                if(check < smallest){
                    smallest = check;
                    pos = new Vector2(200,-200);
                }
                return pos;
    }

    Vector2 GetNormal(Vector2 p) {
        Vector2 n = new Vector2(
            GetDist(p) - GetDist(p - new Vector2(0.125f, 0)),
            GetDist(p) - GetDist(p - new Vector2(0, 0.125f)
        ));
        return n.normalized;
    }

    void Start(){
        InvokeRepeating("UpdateMaterial", 0.1f, delay);
        GameObject.Find("Options").GetComponent<Options>().StartClearing();
    }

    void UpdateMaterial(){
        float totalDist = 0;
        Vector2 newOrigin = startPos;
        float newDist = GetDist(newOrigin)/5;
        
        for (int steps = 0; steps < 10000; steps++){
            newOrigin = newOrigin + newDist * dir;

            dir = ( dir - (GetGravityCentrePosition(newOrigin) - newOrigin).normalized * -0.04f).normalized;

            newDist = GetDist(newOrigin) / 5;
            totalDist = totalDist + newDist;

            

            if(newDist < 1){

                newOrigin = newOrigin - 1.5f * dir;
                dir = dir - 2 * Vector2.Dot(GetNormal(newOrigin), dir) * GetNormal(newOrigin);
                startPos = newOrigin;
                
                break;
            }
        }

        if (dir.x == shaderMat.GetVector("_Dynamic").z && dir.y == shaderMat.GetVector("_Dynamic").w){
            Vector2 dunce = new Vector2(Random.Range(0.1f,-0.1f), Random.Range(0.1f,-0.1f));
            print(dunce);
            dir = (dir + dunce).normalized;
        }
        shaderMat.SetVector("_Dynamic", new Vector4(startPos.x, startPos.y, dir.x, dir.y));

        if(Mathf.Abs((int)(startPos.y/5 + 180) * texture.width) + Mathf.Abs((int)(startPos.x/5 + 320)) < c.Length){
            c[Mathf.Abs((int)(startPos.y/5 + 180) * texture.width) + Mathf.Abs((int)(startPos.x/5 + 320))] = Color.white;
        }
        texture.SetPixels(c);
        texture.Apply();
    }

}
