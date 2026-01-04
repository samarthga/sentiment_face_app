using UnityEngine;

/// <summary>
/// Generates a procedural 3D face with blend shape-like controls.
/// This is a placeholder until a real 3D model is imported.
/// </summary>
public class ProceduralFace : MonoBehaviour
{
    [Header("Face Parts")]
    public Transform head;
    public Transform leftEye;
    public Transform rightEye;
    public Transform leftPupil;
    public Transform rightPupil;
    public Transform leftEyebrow;
    public Transform rightEyebrow;
    public Transform nose;
    public Transform upperLip;
    public Transform lowerLip;
    public Transform mouthCornerLeft;
    public Transform mouthCornerRight;

    [Header("Blend Shape Values (0-1)")]
    [Range(0, 1)] public float browInnerUp = 0;
    [Range(0, 1)] public float browDownLeft = 0;
    [Range(0, 1)] public float browDownRight = 0;
    [Range(0, 1)] public float browOuterUpLeft = 0;
    [Range(0, 1)] public float browOuterUpRight = 0;
    [Range(0, 1)] public float eyeBlinkLeft = 0;
    [Range(0, 1)] public float eyeBlinkRight = 0;
    [Range(0, 1)] public float eyeWideLeft = 0;
    [Range(0, 1)] public float eyeWideRight = 0;
    [Range(0, 1)] public float mouthSmileLeft = 0;
    [Range(0, 1)] public float mouthSmileRight = 0;
    [Range(0, 1)] public float mouthFrownLeft = 0;
    [Range(0, 1)] public float mouthFrownRight = 0;
    [Range(0, 1)] public float mouthOpen = 0;
    [Range(0, 1)] public float jawOpen = 0;

    // Base positions
    private Vector3 leftEyebrowBasePos;
    private Vector3 rightEyebrowBasePos;
    private Vector3 leftEyeBaseScale;
    private Vector3 rightEyeBaseScale;
    private Vector3 upperLipBasePos;
    private Vector3 lowerLipBasePos;
    private Vector3 mouthCornerLeftBasePos;
    private Vector3 mouthCornerRightBasePos;

    private void Start()
    {
        if (head == null) CreateFace();
        StoreBasePositions();
    }

    private void StoreBasePositions()
    {
        if (leftEyebrow) leftEyebrowBasePos = leftEyebrow.localPosition;
        if (rightEyebrow) rightEyebrowBasePos = rightEyebrow.localPosition;
        if (leftEye) leftEyeBaseScale = leftEye.localScale;
        if (rightEye) rightEyeBaseScale = rightEye.localScale;
        if (upperLip) upperLipBasePos = upperLip.localPosition;
        if (lowerLip) lowerLipBasePos = lowerLip.localPosition;
        if (mouthCornerLeft) mouthCornerLeftBasePos = mouthCornerLeft.localPosition;
        if (mouthCornerRight) mouthCornerRightBasePos = mouthCornerRight.localPosition;
    }

    private void Update()
    {
        ApplyBlendShapes();
    }

    public void ApplyBlendShapes()
    {
        // Eyebrows
        if (leftEyebrow)
        {
            Vector3 pos = leftEyebrowBasePos;
            pos.y += browInnerUp * 0.1f + browOuterUpLeft * 0.08f - browDownLeft * 0.08f;
            float rotation = browInnerUp * 10f - browDownLeft * 15f;
            leftEyebrow.localPosition = pos;
            leftEyebrow.localRotation = Quaternion.Euler(0, 0, rotation);
        }

        if (rightEyebrow)
        {
            Vector3 pos = rightEyebrowBasePos;
            pos.y += browInnerUp * 0.1f + browOuterUpRight * 0.08f - browDownRight * 0.08f;
            float rotation = -browInnerUp * 10f + browDownRight * 15f;
            rightEyebrow.localPosition = pos;
            rightEyebrow.localRotation = Quaternion.Euler(0, 0, rotation);
        }

        // Eyes (blink and wide)
        if (leftEye)
        {
            Vector3 scale = leftEyeBaseScale;
            scale.y *= (1f - eyeBlinkLeft * 0.9f) * (1f + eyeWideLeft * 0.3f);
            leftEye.localScale = scale;
        }

        if (rightEye)
        {
            Vector3 scale = rightEyeBaseScale;
            scale.y *= (1f - eyeBlinkRight * 0.9f) * (1f + eyeWideRight * 0.3f);
            rightEye.localScale = scale;
        }

        // Mouth corners (smile/frown)
        if (mouthCornerLeft)
        {
            Vector3 pos = mouthCornerLeftBasePos;
            pos.y += mouthSmileLeft * 0.15f - mouthFrownLeft * 0.1f;
            pos.x -= mouthSmileLeft * 0.05f;
            mouthCornerLeft.localPosition = pos;
        }

        if (mouthCornerRight)
        {
            Vector3 pos = mouthCornerRightBasePos;
            pos.y += mouthSmileRight * 0.15f - mouthFrownRight * 0.1f;
            pos.x += mouthSmileRight * 0.05f;
            mouthCornerRight.localPosition = pos;
        }

        // Jaw/mouth open
        if (lowerLip)
        {
            Vector3 pos = lowerLipBasePos;
            pos.y -= (jawOpen + mouthOpen) * 0.2f;
            lowerLip.localPosition = pos;
        }
    }

    /// <summary>
    /// Set emotions from the sentiment data
    /// </summary>
    public void SetEmotions(float happiness, float sadness, float anger, float fear, float surprise, float disgust)
    {
        // Map emotions to blend shapes
        float smile = happiness;
        float frown = sadness * 0.7f + anger * 0.3f;

        mouthSmileLeft = smile;
        mouthSmileRight = smile;
        mouthFrownLeft = frown;
        mouthFrownRight = frown;

        // Eyebrows
        browInnerUp = sadness * 0.6f + fear * 0.4f + surprise * 0.5f;
        browDownLeft = anger * 0.8f;
        browDownRight = anger * 0.8f;
        browOuterUpLeft = surprise * 0.5f;
        browOuterUpRight = surprise * 0.5f;

        // Eyes
        eyeWideLeft = surprise * 0.6f + fear * 0.4f;
        eyeWideRight = surprise * 0.6f + fear * 0.4f;

        // Mouth open for surprise
        jawOpen = surprise * 0.5f;
        mouthOpen = surprise * 0.3f;
    }

    private void CreateFace()
    {
        // Create head
        head = CreateSphere("Head", Vector3.zero, new Vector3(2f, 2.4f, 2f), GetSkinMaterial());

        // Create eyes
        leftEye = CreateSphere("LeftEye", new Vector3(-0.4f, 0.3f, 0.85f), Vector3.one * 0.35f, GetWhiteMaterial());
        rightEye = CreateSphere("RightEye", new Vector3(0.4f, 0.3f, 0.85f), Vector3.one * 0.35f, GetWhiteMaterial());

        // Create pupils
        leftPupil = CreateSphere("LeftPupil", new Vector3(-0.4f, 0.3f, 1.0f), Vector3.one * 0.15f, GetDarkMaterial());
        rightPupil = CreateSphere("RightPupil", new Vector3(0.4f, 0.3f, 1.0f), Vector3.one * 0.15f, GetDarkMaterial());

        // Create eyebrows
        leftEyebrow = CreateCube("LeftEyebrow", new Vector3(-0.4f, 0.65f, 0.9f), new Vector3(0.5f, 0.08f, 0.1f), GetHairMaterial());
        rightEyebrow = CreateCube("RightEyebrow", new Vector3(0.4f, 0.65f, 0.9f), new Vector3(0.5f, 0.08f, 0.1f), GetHairMaterial());

        // Create nose
        nose = CreateSphere("Nose", new Vector3(0, -0.1f, 1.0f), new Vector3(0.25f, 0.3f, 0.25f), GetSkinMaterial());

        // Create mouth parts
        upperLip = CreateCube("UpperLip", new Vector3(0, -0.55f, 0.95f), new Vector3(0.6f, 0.08f, 0.15f), GetLipMaterial());
        lowerLip = CreateCube("LowerLip", new Vector3(0, -0.7f, 0.92f), new Vector3(0.5f, 0.1f, 0.15f), GetLipMaterial());
        mouthCornerLeft = CreateSphere("MouthCornerL", new Vector3(-0.35f, -0.6f, 0.9f), Vector3.one * 0.08f, GetLipMaterial());
        mouthCornerRight = CreateSphere("MouthCornerR", new Vector3(0.35f, -0.6f, 0.9f), Vector3.one * 0.08f, GetLipMaterial());

        StoreBasePositions();
    }

    private Transform CreateSphere(string name, Vector3 position, Vector3 scale, Material material)
    {
        GameObject go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        go.name = name;
        go.transform.SetParent(transform);
        go.transform.localPosition = position;
        go.transform.localScale = scale;
        go.GetComponent<Renderer>().material = material;
        Destroy(go.GetComponent<Collider>());
        return go.transform;
    }

    private Transform CreateCube(string name, Vector3 position, Vector3 scale, Material material)
    {
        GameObject go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.name = name;
        go.transform.SetParent(transform);
        go.transform.localPosition = position;
        go.transform.localScale = scale;
        go.GetComponent<Renderer>().material = material;
        Destroy(go.GetComponent<Collider>());
        return go.transform;
    }

    private Material GetSkinMaterial()
    {
        Material mat = new Material(Shader.Find("Standard"));
        mat.color = new Color(1f, 0.87f, 0.77f); // Skin tone
        mat.SetFloat("_Smoothness", 0.3f);
        return mat;
    }

    private Material GetWhiteMaterial()
    {
        Material mat = new Material(Shader.Find("Standard"));
        mat.color = Color.white;
        mat.SetFloat("_Smoothness", 0.8f);
        return mat;
    }

    private Material GetDarkMaterial()
    {
        Material mat = new Material(Shader.Find("Standard"));
        mat.color = new Color(0.15f, 0.1f, 0.08f);
        return mat;
    }

    private Material GetHairMaterial()
    {
        Material mat = new Material(Shader.Find("Standard"));
        mat.color = new Color(0.2f, 0.15f, 0.1f);
        return mat;
    }

    private Material GetLipMaterial()
    {
        Material mat = new Material(Shader.Find("Standard"));
        mat.color = new Color(0.8f, 0.5f, 0.5f);
        mat.SetFloat("_Smoothness", 0.5f);
        return mat;
    }
}
