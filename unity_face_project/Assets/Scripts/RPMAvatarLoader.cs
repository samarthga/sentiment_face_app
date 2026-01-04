using System;
using UnityEngine;

/// <summary>
/// Loads Ready Player Me avatar and sets up face controller.
/// Works with the Ready Player Me Unity SDK.
/// </summary>
public class RPMAvatarLoader : MonoBehaviour
{
    [Header("Avatar Settings")]
    [Tooltip("Your Ready Player Me avatar URL")]
    public string avatarUrl = "https://models.readyplayer.me/69583872220569853ff8386e.glb";

    [Header("Loaded References")]
    public GameObject avatar;
    public SkinnedMeshRenderer headMesh;
    public FaceController faceController;

    private void Start()
    {
        SetupScene();
        LoadAvatar();
    }

    private void SetupScene()
    {
        // Camera setup
        var cam = Camera.main;
        if (cam != null)
        {
            cam.transform.position = new Vector3(0, 1.65f, 0.8f);
            cam.transform.rotation = Quaternion.Euler(0, 180, 0);
            cam.backgroundColor = new Color(0.12f, 0.12f, 0.18f);
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.fieldOfView = 35f;
        }

        // Lighting
        var lights = FindObjectsOfType<Light>();
        foreach (var l in lights) Destroy(l.gameObject);

        // Key light
        var keyLight = new GameObject("Key Light").AddComponent<Light>();
        keyLight.type = LightType.Directional;
        keyLight.intensity = 1.2f;
        keyLight.color = new Color(1f, 0.98f, 0.95f);
        keyLight.transform.rotation = Quaternion.Euler(35, -30, 0);

        // Fill light
        var fillLight = new GameObject("Fill Light").AddComponent<Light>();
        fillLight.type = LightType.Directional;
        fillLight.intensity = 0.6f;
        fillLight.color = new Color(0.9f, 0.95f, 1f);
        fillLight.transform.rotation = Quaternion.Euler(20, 150, 0);

        // Rim light
        var rimLight = new GameObject("Rim Light").AddComponent<Light>();
        rimLight.type = LightType.Directional;
        rimLight.intensity = 0.4f;
        rimLight.color = new Color(0.8f, 0.85f, 1f);
        rimLight.transform.rotation = Quaternion.Euler(-10, 180, 0);

        // Ambient
        RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
        RenderSettings.ambientLight = new Color(0.35f, 0.35f, 0.4f);
    }

    private void LoadAvatar()
    {
        Debug.Log($"[RPMAvatarLoader] Loading avatar: {avatarUrl}");

        // Check if Ready Player Me SDK is available
        var loaderType = Type.GetType("ReadyPlayerMe.AvatarLoading.AvatarObjectLoader, ReadyPlayerMe.AvatarLoading");

        if (loaderType != null)
        {
            Debug.Log("[RPMAvatarLoader] Ready Player Me SDK found, loading avatar...");
            LoadWithSDK();
        }
        else
        {
            Debug.LogWarning("[RPMAvatarLoader] Ready Player Me SDK not found!");
            Debug.Log("Please install the SDK via Package Manager:");
            Debug.Log("1. Window -> Package Manager");
            Debug.Log("2. Click + -> Add package from git URL");
            Debug.Log("3. Add: https://github.com/readyplayerme/rpm-unity-sdk-core.git");
            Debug.Log("4. Add: https://github.com/readyplayerme/rpm-unity-sdk-avatar-loader.git");
            Debug.Log("");
            Debug.Log("After installing, press Play again.");

            // Create procedural face as fallback
            CreateProceduralFallback();
        }
    }

    private void LoadWithSDK()
    {
        try
        {
            // Use reflection to call Ready Player Me SDK
            var loaderType = Type.GetType("ReadyPlayerMe.AvatarLoading.AvatarObjectLoader, ReadyPlayerMe.AvatarLoading");
            var loader = Activator.CreateInstance(loaderType);

            // Set up callbacks using reflection
            var onCompletedField = loaderType.GetField("OnCompleted");
            var onFailedField = loaderType.GetField("OnFailed");

            // Create delegate for OnCompleted
            var completedDelegateType = onCompletedField.FieldType;
            var onAvatarLoaded = Delegate.CreateDelegate(
                completedDelegateType,
                this,
                typeof(RPMAvatarLoader).GetMethod("OnAvatarLoaded", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance)
            );
            onCompletedField.SetValue(loader, onAvatarLoaded);

            // Call LoadAvatar
            var loadMethod = loaderType.GetMethod("LoadAvatar");
            loadMethod.Invoke(loader, new object[] { avatarUrl });
        }
        catch (Exception e)
        {
            Debug.LogError($"[RPMAvatarLoader] Error loading with SDK: {e.Message}");
            CreateProceduralFallback();
        }
    }

    // Called when avatar is loaded (via reflection)
    private void OnAvatarLoaded(object sender, object args)
    {
        try
        {
            var argsType = args.GetType();
            var avatarProp = argsType.GetProperty("Avatar");
            avatar = avatarProp.GetValue(args) as GameObject;

            if (avatar != null)
            {
                SetupLoadedAvatar();
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"[RPMAvatarLoader] Error setting up avatar: {e.Message}");
        }
    }

    private void SetupLoadedAvatar()
    {
        Debug.Log("[RPMAvatarLoader] Avatar loaded successfully!");

        // Position avatar
        avatar.transform.position = Vector3.zero;
        avatar.transform.rotation = Quaternion.identity;

        // Find head mesh with blend shapes
        var meshRenderers = avatar.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var mesh in meshRenderers)
        {
            if (mesh.sharedMesh != null && mesh.sharedMesh.blendShapeCount > 0)
            {
                // Check if it has face blend shapes
                int browIndex = mesh.sharedMesh.GetBlendShapeIndex("browInnerUp");
                int smileIndex = mesh.sharedMesh.GetBlendShapeIndex("mouthSmileLeft");

                if (browIndex >= 0 || smileIndex >= 0)
                {
                    headMesh = mesh;
                    Debug.Log($"[RPMAvatarLoader] Found head mesh: {mesh.name} with {mesh.sharedMesh.blendShapeCount} blend shapes");
                    break;
                }
            }
        }

        if (headMesh == null && meshRenderers.Length > 0)
        {
            // Use first mesh with blend shapes
            foreach (var mesh in meshRenderers)
            {
                if (mesh.sharedMesh != null && mesh.sharedMesh.blendShapeCount > 0)
                {
                    headMesh = mesh;
                    Debug.Log($"[RPMAvatarLoader] Using mesh: {mesh.name} with {mesh.sharedMesh.blendShapeCount} blend shapes");
                    break;
                }
            }
        }

        // Add FaceController
        faceController = avatar.AddComponent<FaceController>();

        // Add FlutterMessageHandler to scene
        if (FindObjectOfType<FlutterMessageHandler>() == null)
        {
            var handler = new GameObject("FlutterMessageHandler").AddComponent<FlutterMessageHandler>();
        }

        Debug.Log("[RPMAvatarLoader] Avatar setup complete!");
        LogBlendShapes();
    }

    private void LogBlendShapes()
    {
        if (headMesh == null || headMesh.sharedMesh == null) return;

        Debug.Log("[RPMAvatarLoader] Available blend shapes:");
        for (int i = 0; i < headMesh.sharedMesh.blendShapeCount; i++)
        {
            Debug.Log($"  [{i}] {headMesh.sharedMesh.GetBlendShapeName(i)}");
        }
    }

    private void CreateProceduralFallback()
    {
        Debug.Log("[RPMAvatarLoader] Creating procedural face as fallback...");

        avatar = new GameObject("ProceduralAvatar");
        avatar.transform.position = new Vector3(0, 1.5f, 0);

        var face = avatar.AddComponent<ProceduralFace>();
        faceController = avatar.AddComponent<FaceController>();

        if (FindObjectOfType<FlutterMessageHandler>() == null)
        {
            new GameObject("FlutterMessageHandler").AddComponent<FlutterMessageHandler>();
        }

        Debug.Log("[RPMAvatarLoader] Procedural face created. Install Ready Player Me SDK for realistic avatar.");
    }

    // Test methods
    [ContextMenu("Test Happy Expression")]
    public void TestHappy()
    {
        if (faceController != null)
            faceController.SetEmotion("{\"happiness\":0.9,\"sadness\":0,\"anger\":0,\"fear\":0,\"surprise\":0.1,\"disgust\":0}");
    }

    [ContextMenu("Test Sad Expression")]
    public void TestSad()
    {
        if (faceController != null)
            faceController.SetEmotion("{\"happiness\":0,\"sadness\":0.8,\"anger\":0,\"fear\":0.1,\"surprise\":0,\"disgust\":0}");
    }

    [ContextMenu("Test Angry Expression")]
    public void TestAngry()
    {
        if (faceController != null)
            faceController.SetEmotion("{\"happiness\":0,\"sadness\":0.1,\"anger\":0.9,\"fear\":0,\"surprise\":0,\"disgust\":0.2}");
    }

    [ContextMenu("Test Surprised Expression")]
    public void TestSurprised()
    {
        if (faceController != null)
            faceController.SetEmotion("{\"happiness\":0.2,\"sadness\":0,\"anger\":0,\"fear\":0.3,\"surprise\":0.9,\"disgust\":0}");
    }

    [ContextMenu("Test Neutral Expression")]
    public void TestNeutral()
    {
        if (faceController != null)
            faceController.SetEmotion("{\"happiness\":0.1,\"sadness\":0.05,\"anger\":0,\"fear\":0,\"surprise\":0,\"disgust\":0}");
    }
}
