using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class TAfterEffect : MonoBehaviour
{
    public Material BSCMat;
    [Range(0.0f, 3.0f)]
    public float Brightness = 1.0f;
    [Range(0.0f, 3.0f)]
    public float Saturation = 1.0f;
    [Range(0.0f, 3.0f)]
    public float Contrast = 1.0f;

    public bool UseEdge = false;
    [Range(0.0f, 1.0f)]
    public float EdgesOnly = 0.0f;
    public Color EdgeColor = Color.black;
    public Color BackgroundColor = Color.white;

    // Start is called before the first frame update
    void Start()
    {
        if(SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        {
            this.enabled = false;
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (this.BSCMat == null)
        {
            return;
        }
        this.BSCMat.SetFloat("_Brightness", this.Brightness);
        this.BSCMat.SetFloat("_Saturation", this.Saturation);
        this.BSCMat.SetFloat("_Contrast", this.Contrast);

        this.BSCMat.SetFloat("_EdgesOnly", this.EdgesOnly);
        this.BSCMat.SetColor("_EdgeColor", this.EdgeColor);
        this.BSCMat.SetColor("_BackgroundColor", this.BackgroundColor);
        this.BSCMat.SetInt("_UseEdge", (this.UseEdge == true ? 1 : 0));


        Graphics.Blit(source, destination, this.BSCMat);
    }
}


