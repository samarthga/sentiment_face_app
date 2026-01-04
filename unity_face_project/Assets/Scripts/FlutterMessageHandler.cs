using System;
using UnityEngine;

/// <summary>
/// Handles messages from Flutter via flutter_unity_widget.
/// Attach this to a GameObject in your scene.
/// </summary>
public class FlutterMessageHandler : MonoBehaviour
{
    [SerializeField] private FaceController faceController;

    private static FlutterMessageHandler _instance;
    public static FlutterMessageHandler Instance => _instance;

    private void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        DontDestroyOnLoad(gameObject);
    }

    private void Start()
    {
        if (faceController == null)
        {
            faceController = FindObjectOfType<FaceController>();
        }

        // Notify Flutter that Unity is ready
        SendMessageToFlutter("unity_ready", "true");
    }

    /// <summary>
    /// Called by Flutter to set emotion state.
    /// Message format: JSON with emotion values
    /// </summary>
    public void SetEmotion(string jsonMessage)
    {
        Debug.Log($"[FlutterMessageHandler] Received emotion: {jsonMessage}");

        if (faceController != null)
        {
            faceController.SetEmotion(jsonMessage);
        }
        else
        {
            Debug.LogWarning("[FlutterMessageHandler] FaceController not found!");
        }
    }

    /// <summary>
    /// Called by Flutter to set individual emotion value.
    /// Message format: "emotionName:value" (e.g., "happiness:0.8")
    /// </summary>
    public void SetSingleEmotion(string message)
    {
        Debug.Log($"[FlutterMessageHandler] Received single emotion: {message}");

        try
        {
            var parts = message.Split(':');
            if (parts.Length == 2)
            {
                string emotionName = parts[0].Trim();
                float value = float.Parse(parts[1].Trim());

                // Create JSON message for FaceController
                string json = $"{{\"type\":\"setEmotion\",\"{emotionName}\":{value}}}";
                if (faceController != null)
                {
                    faceController.SetEmotion(json);
                }
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"[FlutterMessageHandler] Error parsing emotion: {e.Message}");
        }
    }

    /// <summary>
    /// Send a message back to Flutter.
    /// </summary>
    public void SendMessageToFlutter(string objectName, string message)
    {
        #if UNITY_ANDROID || UNITY_IOS
        try
        {
            // flutter_unity_widget uses UnityMessageManager
            UnityMessageManager.Instance?.SendMessageToFlutter(message);
        }
        catch (Exception e)
        {
            Debug.Log($"[FlutterMessageHandler] Could not send to Flutter: {e.Message}");
        }
        #endif

        Debug.Log($"[FlutterMessageHandler] To Flutter: {objectName} = {message}");
    }

    /// <summary>
    /// Called when scene loads
    /// </summary>
    public void OnSceneLoaded(string sceneName)
    {
        Debug.Log($"[FlutterMessageHandler] Scene loaded: {sceneName}");
        SendMessageToFlutter("scene_loaded", sceneName);
    }
}

/// <summary>
/// Placeholder for UnityMessageManager from flutter_unity_widget.
/// This will be replaced by the actual package.
/// </summary>
#if !FLUTTER_UNITY_WIDGET
public class UnityMessageManager : MonoBehaviour
{
    private static UnityMessageManager _instance;
    public static UnityMessageManager Instance
    {
        get
        {
            if (_instance == null)
            {
                var go = new GameObject("UnityMessageManager");
                _instance = go.AddComponent<UnityMessageManager>();
                DontDestroyOnLoad(go);
            }
            return _instance;
        }
    }

    public void SendMessageToFlutter(string message)
    {
        Debug.Log($"[UnityMessageManager] Would send to Flutter: {message}");
    }
}
#endif
