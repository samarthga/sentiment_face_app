using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Networking;

/// <summary>
/// Reads emotion data from the sentiment backend API and updates the face.
/// </summary>
public class BackendEmotionReader : MonoBehaviour
{
    [Header("Backend Settings")]
    public string backendUrl = "http://localhost:8000/api/v1/sentiment/current";
    public float pollInterval = 2f; // How often to fetch (seconds)

    [Header("Emotion Scaling")]
    [Range(0.1f, 1f)]
    public float emotionScale = 0.1f; // Scale down emotions (0.1 = 10% intensity)
    [Range(0f, 0.5f)]
    public float emotionFloor = 0.02f; // Minimum emotion value for subtle expression
    [Range(1f, 10f)]
    public float smoothSpeed = 3f; // How fast to transition between emotions

    [Header("Face Controller")]
    public SimpleFaceController faceController;

    [Header("Status")]
    public bool isConnected = false;
    public string lastError = "";
    public EmotionData lastEmotion;

    // Target values for smooth transitions
    private float targetHappiness;
    private float targetSadness;
    private float targetAnger;
    private float targetFear;
    private float targetSurprise;
    private float targetDisgust;

    private void Start()
    {
        if (faceController == null)
        {
            faceController = FindObjectOfType<SimpleFaceController>();
        }

        StartCoroutine(PollBackend());
    }

    private void Update()
    {
        if (faceController == null) return;

        // Smoothly interpolate emotions toward target values
        float t = Time.deltaTime * smoothSpeed;
        faceController.happiness = Mathf.Lerp(faceController.happiness, targetHappiness, t);
        faceController.sadness = Mathf.Lerp(faceController.sadness, targetSadness, t);
        faceController.anger = Mathf.Lerp(faceController.anger, targetAnger, t);
        faceController.fear = Mathf.Lerp(faceController.fear, targetFear, t);
        faceController.surprise = Mathf.Lerp(faceController.surprise, targetSurprise, t);
        faceController.disgust = Mathf.Lerp(faceController.disgust, targetDisgust, t);
    }

    IEnumerator PollBackend()
    {
        while (true)
        {
            yield return FetchEmotions();
            yield return new WaitForSeconds(pollInterval);
        }
    }

    IEnumerator FetchEmotions()
    {
        using (UnityWebRequest request = UnityWebRequest.Get(backendUrl))
        {
            request.timeout = 5;

            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                isConnected = true;
                lastError = "";

                try
                {
                    string json = request.downloadHandler.text;
                    EmotionData data = JsonUtility.FromJson<EmotionData>(json);
                    lastEmotion = data;

                    ApplyEmotions(data);

                    Debug.Log($"[Backend] Emotions - Happy:{data.happiness:F2} Sad:{data.sadness:F2} Angry:{data.anger:F2} Surprise:{data.surprise:F2}");
                }
                catch (Exception e)
                {
                    lastError = $"Parse error: {e.Message}";
                    Debug.LogError($"[Backend] {lastError}");
                }
            }
            else
            {
                isConnected = false;
                lastError = request.error;
                Debug.LogWarning($"[Backend] Connection failed: {request.error}");
            }
        }
    }

    void ApplyEmotions(EmotionData data)
    {
        if (faceController == null) return;

        // Find top 2 emotions and only display those for natural look
        var emotions = new (string name, float value)[]
        {
            ("happiness", data.happiness),
            ("sadness", data.sadness),
            ("anger", data.anger),
            ("fear", data.fear),
            ("surprise", data.surprise),
            ("disgust", data.disgust)
        };

        // Sort by value descending
        System.Array.Sort(emotions, (a, b) => b.value.CompareTo(a.value));

        // Reset all targets to zero
        targetHappiness = 0;
        targetSadness = 0;
        targetAnger = 0;
        targetFear = 0;
        targetSurprise = 0;
        targetDisgust = 0;

        // Apply only top 2 emotions
        for (int i = 0; i < 2 && i < emotions.Length; i++)
        {
            float scaledValue = emotions[i].value * emotionScale;
            switch (emotions[i].name)
            {
                case "happiness": targetHappiness = scaledValue; break;
                case "sadness": targetSadness = scaledValue; break;
                case "anger": targetAnger = scaledValue; break;
                case "fear": targetFear = scaledValue; break;
                case "surprise": targetSurprise = scaledValue; break;
                case "disgust": targetDisgust = scaledValue; break;
            }
        }

        Debug.Log($"[Backend] Top emotions: {emotions[0].name}={emotions[0].value:F2}, {emotions[1].name}={emotions[1].value:F2}");
    }

    [ContextMenu("Test Fetch Now")]
    public void TestFetch()
    {
        StartCoroutine(FetchEmotions());
    }

    [ContextMenu("Toggle Connection")]
    public void ToggleConnection()
    {
        if (isConnected)
        {
            StopAllCoroutines();
            isConnected = false;
            Debug.Log("[Backend] Disconnected");
        }
        else
        {
            StartCoroutine(PollBackend());
            Debug.Log("[Backend] Reconnecting...");
        }
    }
}

[Serializable]
public class EmotionData
{
    public float happiness;
    public float sadness;
    public float anger;
    public float fear;
    public float surprise;
    public float disgust;
    public float confusion;
    public float pride;
    public float loneliness;
    public float pain;
    public float contempt;
    public float anticipation;
    public float trust;
    public float overallSentiment;
    public float intensity;
    public string timestamp;
}
