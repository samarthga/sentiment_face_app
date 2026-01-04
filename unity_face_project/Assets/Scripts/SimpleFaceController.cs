using UnityEngine;

/// <summary>
/// Simple face controller for Ready Player Me avatars.
/// Add this to any GameObject, then assign the head mesh.
/// </summary>
public class SimpleFaceController : MonoBehaviour
{
    [Header("Drag the Wolf3D_Head mesh here")]
    public SkinnedMeshRenderer headMesh;

    [Header("Current Emotions (0-1)")]
    [Range(0, 1)] public float happiness = 0;
    [Range(0, 1)] public float sadness = 0;
    [Range(0, 1)] public float anger = 0;
    [Range(0, 1)] public float fear = 0;
    [Range(0, 1)] public float surprise = 0;
    [Range(0, 1)] public float disgust = 0;

    [Header("Settings")]
    public float transitionSpeed = 3f;
    public bool autoBlink = true;

    // Internal
    private float blinkTimer;
    private float blinkValue;
    private bool isBlinking;

    void Start()
    {
        if (headMesh == null)
        {
            // Try to find head mesh automatically
            var meshes = GetComponentsInChildren<SkinnedMeshRenderer>();
            foreach (var mesh in meshes)
            {
                if (mesh.name.Contains("Head") || mesh.name.Contains("Wolf3D"))
                {
                    if (mesh.sharedMesh != null && mesh.sharedMesh.blendShapeCount > 20)
                    {
                        headMesh = mesh;
                        Debug.Log($"[SimpleFaceController] Auto-found head mesh: {mesh.name}");
                        break;
                    }
                }
            }
        }

        if (headMesh != null)
        {
            Debug.Log($"[SimpleFaceController] Ready! Blend shapes: {headMesh.sharedMesh.blendShapeCount}");
        }
    }

    void Update()
    {
        if (headMesh == null) return;

        // Auto blink
        if (autoBlink)
        {
            UpdateBlink();
        }

        // Apply emotions to blend shapes
        ApplyEmotions();
    }

    void UpdateBlink()
    {
        blinkTimer += Time.deltaTime;

        if (!isBlinking && blinkTimer > Random.Range(2f, 5f))
        {
            isBlinking = true;
            blinkTimer = 0;
        }

        if (isBlinking)
        {
            blinkValue += Time.deltaTime * 15f;
            if (blinkValue >= Mathf.PI)
            {
                blinkValue = 0;
                isBlinking = false;
            }
        }

        float blink = Mathf.Sin(blinkValue) * 100f;
        SetBlendShape("eyeBlinkLeft", blink);
        SetBlendShape("eyeBlinkRight", blink);
    }

    void ApplyEmotions()
    {
        // Smile (happiness)
        float smile = happiness * 100f;
        SetBlendShape("mouthSmileLeft", smile);
        SetBlendShape("mouthSmileRight", smile);
        SetBlendShape("cheekSquintLeft", smile * 0.5f);
        SetBlendShape("cheekSquintRight", smile * 0.5f);

        // Frown (sadness)
        float frown = sadness * 100f;
        SetBlendShape("mouthFrownLeft", frown);
        SetBlendShape("mouthFrownRight", frown);
        SetBlendShape("browInnerUp", frown * 0.7f);

        // Anger
        float angry = anger * 100f;
        SetBlendShape("browDownLeft", angry);
        SetBlendShape("browDownRight", angry);
        SetBlendShape("eyeSquintLeft", angry * 0.5f);
        SetBlendShape("eyeSquintRight", angry * 0.5f);
        SetBlendShape("noseSneerLeft", angry * 0.3f);
        SetBlendShape("noseSneerRight", angry * 0.3f);

        // Fear
        float scared = fear * 100f;
        SetBlendShape("eyeWideLeft", scared * 0.7f);
        SetBlendShape("eyeWideRight", scared * 0.7f);
        SetBlendShape("browInnerUp", Mathf.Max(frown * 0.7f, scared * 0.5f));

        // Surprise
        float surprised = surprise * 100f;
        SetBlendShape("eyeWideLeft", Mathf.Max(scared * 0.7f, surprised));
        SetBlendShape("eyeWideRight", Mathf.Max(scared * 0.7f, surprised));
        SetBlendShape("browOuterUpLeft", surprised * 0.8f);
        SetBlendShape("browOuterUpRight", surprised * 0.8f);
        SetBlendShape("jawOpen", surprised * 0.5f);
        SetBlendShape("mouthOpen", surprised * 0.3f);

        // Disgust
        float disgusted = disgust * 100f;
        SetBlendShape("noseSneerLeft", Mathf.Max(angry * 0.3f, disgusted * 0.8f));
        SetBlendShape("noseSneerRight", Mathf.Max(angry * 0.3f, disgusted * 0.8f));
        SetBlendShape("mouthUpperUpLeft", disgusted * 0.5f);
        SetBlendShape("mouthUpperUpRight", disgusted * 0.5f);
    }

    void SetBlendShape(string name, float value)
    {
        if (headMesh == null || headMesh.sharedMesh == null) return;

        int index = headMesh.sharedMesh.GetBlendShapeIndex(name);
        if (index >= 0)
        {
            headMesh.SetBlendShapeWeight(index, Mathf.Clamp(value, 0, 100));
        }
    }

    /// <summary>
    /// Call this from Flutter
    /// </summary>
    public void SetEmotion(string json)
    {
        var data = JsonUtility.FromJson<EmotionInput>(json);
        happiness = data.happiness;
        sadness = data.sadness;
        anger = data.anger;
        fear = data.fear;
        surprise = data.surprise;
        disgust = data.disgust;
    }

    [System.Serializable]
    private class EmotionInput
    {
        public float happiness;
        public float sadness;
        public float anger;
        public float fear;
        public float surprise;
        public float disgust;
    }

    // Test buttons in Inspector
    [ContextMenu("Test Happy")]
    void TestHappy() { happiness = 0.9f; sadness = 0; anger = 0; fear = 0; surprise = 0; disgust = 0; }

    [ContextMenu("Test Sad")]
    void TestSad() { happiness = 0; sadness = 0.8f; anger = 0; fear = 0; surprise = 0; disgust = 0; }

    [ContextMenu("Test Angry")]
    void TestAngry() { happiness = 0; sadness = 0; anger = 0.9f; fear = 0; surprise = 0; disgust = 0; }

    [ContextMenu("Test Surprised")]
    void TestSurprised() { happiness = 0; sadness = 0; anger = 0; fear = 0; surprise = 0.9f; disgust = 0; }

    [ContextMenu("Test Neutral")]
    void TestNeutral() { happiness = 0.1f; sadness = 0; anger = 0; fear = 0; surprise = 0; disgust = 0; }
}
