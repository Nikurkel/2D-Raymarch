using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Options : MonoBehaviour
{

    void Update()
    {

        if(Input.GetKeyDown("escape")){
            Application.Quit();
        }
        if(Input.GetKeyDown("space")){
            StartClearing();
        }
    }

    public void StartClearing(){
        StartCoroutine(clearScreen());
    }

    public IEnumerator clearScreen()
    {
        GameObject.Find("Main Camera").GetComponent<Camera>().backgroundColor = Color.black;
        GameObject.Find("Main Camera").GetComponent<Camera>().clearFlags = CameraClearFlags.SolidColor;

        yield return new WaitForSeconds(0.5f);

        GameObject.Find("Main Camera").GetComponent<Camera>().clearFlags = CameraClearFlags.Nothing;
    }

}
