using UnityEngine;

/// <summary>
/// Helper script to set up Ready Player Me avatar with FaceController.
/// Attach this to an empty GameObject, enter your avatar URL, and press Play.
/// </summary>
public class AvatarSetup : MonoBehaviour
{
    [Header("Ready Player Me")]
    [Tooltip("Paste your Ready Player Me avatar URL here (e.g., https://models.readyplayer.me/xxxxx.glb)")]
    public string avatarUrl = "";

    [Header("Scene Setup")]
    public Camera mainCamera;
    public Light mainLight;

    [Header("References (Auto-populated)")]
    public GameObject loadedAvatar;
    public SkinnedMeshRenderer faceMesh;
    public FaceController faceController;

    private bool isLoading = false;

    private void Start()
    {
        SetupScene();

        if (!string.IsNullOrEmpty(avatarUrl))
        {
            LoadAvatar();
        }
        else
        {
            Debug.Log("[AvatarSetup] No avatar URL set. Enter your Ready Player Me URL in the Inspector.");
        }
    }

    private void SetupScene()
    {
        // Set up camera if not assigned
        if (mainCamera == null)
        {
            mainCamera = Camera.main;
            if (mainCamera == null)
            {
                var camGO = new GameObject("Main Camera");
                mainCamera = camGO.AddComponent<Camera>();
                camGO.AddComponent<AudioListener>();
                camGO.tag = "MainCamera";
            }
        }
        mainCamera.transform.position = new Vector3(0, 1.6f, 1.5f);
        mainCamera.transform.LookAt(new Vector3(0, 1.5f, 0));
        mainCamera.backgroundColor = new Color(0.15f, 0.15f, 0.2f);
        mainCamera.clearFlags = CameraClearFlags.SolidColor;

        // Set up lighting
        if (mainLight == null)
        {
            var lightGO = new GameObject("Main Light");
            mainLight = lightGO.AddComponent<Light>();
            mainLight.type = LightType.Directional;
            mainLight.intensity = 1f;
            mainLight.transform.rotation = Quaternion.Euler(50, -30, 0);
        }

        // Add fill light
        var fillLightGO = new GameObject("Fill Light");
        var fillLight = fillLightGO.AddComponent<Light>();
        fillLight.type = LightType.Directional;
        fillLight.intensity = 0.5f;
        fillLight.transform.rotation = Quaternion.Euler(20, 150, 0);

        // Ambient lighting
        RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
        RenderSettings.ambientLight = new Color(0.4f, 0.4f, 0.45f);
    }

    public void LoadAvatar()
    {
        if (isLoading) return;
        if (string.IsNullOrEmpty(avatarUrl))
        {
            Debug.LogError("[AvatarSetup] Avatar URL is empty!");
            return;
        }

        isLoading = true;
        Debug.Log($"[AvatarSetup] Loading avatar from: {avatarUrl}");

        // Try to use Ready Player Me SDK if available
        #if RPM_AVATAR_LOADER
        LoadWithRPMSDK();
        #else
        // Fallback: provide instructions
        Debug.Log("[AvatarSetup] Ready Player Me SDK not found. Please install it via Package Manager:");
        Debug.Log("1. Window -> Package Manager");
        Debug.Log("2. + -> Add package from git URL");
        Debug.Log("3. https://github.com/readyplayerme/rpm-unity-sdk-core.git");
        Debug.Log("4. https://github.com/readyplayerme/rpm-unity-sdk-avatar-loader.git");

        // Create placeholder
        CreatePlaceholder();
        #endif
    }

    private void CreatePlaceholder()
    {
        Debug.Log("[AvatarSetup] Creating placeholder face for testing...");

        // Create a simple placeholder head
        loadedAvatar = new GameObject("PlaceholderAvatar");
        loadedAvatar.transform.position = new Vector3(0, 1.5f, 0);

        // Add ProceduralFace
        var proceduralFace = loadedAvatar.AddComponent<ProceduralFace>();

        // Add FaceController
        faceController = loadedAvatar.AddComponent<FaceController>();

        // Add FlutterMessageHandler
        var messageHandler = loadedAvatar.AddComponent<FlutterMessageHandler>();

        Debug.Log("[AvatarSetup] Placeholder avatar created. Add Ready Player Me SDK for realistic avatar.");
        isLoading = false;
    }

    /// <summary>
    /// Call this from a UI button or after SDK is installed
    /// </summary>
    [ContextMenu("Reload Avatar")]
    public void ReloadAvatar()
    {
        if (loadedAvatar != null)
        {
            Destroy(loadedAvatar);
        }
        isLoading = false;
        LoadAvatar();
    }

    /// <summary>
    /// Test emotions in editor
    /// </summary>
    [ContextMenu("Test Happy")]
    public void TestHappy()
    {
        if (faceController != null)
        {
            string json = "{\"happiness\":0.8,\"sadness\":0,\"anger\":0,\"fear\":0,\"surprise\":0,\"disgust\":0}";
            faceController.SetEmotion(json);
        }
    }

    [ContextMenu("Test Sad")]
    public void TestSad()
    {
        if (faceController != null)
        {
            string json = "{\"happiness\":0,\"sadness\":0.8,\"anger\":0,\"fear\":0,\"surprise\":0,\"disgust\":0}";
            faceController.SetEmotion(json);
        }
    }

    [ContextMenu("Test Angry")]
    public void TestAngry()
    {
        if (faceController != null)
        {
            string json = "{\"happiness\":0,\"sadness\":0,\"anger\":0.8,\"fear\":0,\"surprise\":0,\"disgust\":0}";
            faceController.SetEmotion(json);
        }
    }

    [ContextMenu("Test Surprise")]
    public void TestSurprise()
    {
        if (faceController != null)
        {
            string json = "{\"happiness\":0,\"sadness\":0,\"anger\":0,\"fear\":0,\"surprise\":0.9,\"disgust\":0}";
            faceController.SetEmotion(json);
        }
    }
}
