using System;
using System.Collections;
using UnityEngine;

/// <summary>
/// Controls the 3D face blend shapes based on emotion state received from Flutter.
/// Attach this script to your face mesh that has blend shapes.
/// </summary>
public class FaceController : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private SkinnedMeshRenderer faceRenderer;

    [Header("Animation Settings")]
    [SerializeField] private float transitionDuration = 0.5f;
    [SerializeField] private AnimationCurve transitionCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);

    [Header("Micro-expressions")]
    [SerializeField] private float blinkInterval = 3f;
    [SerializeField] private float blinkDuration = 0.15f;
    [SerializeField] private bool enableBreathing = true;
    [SerializeField] private float breathingSpeed = 0.3f;

    // Blend shape indices (configure these based on your face model)
    // These correspond to ARKit/MetaHuman blend shape naming
    private int _innerBrowRaiseIndex = -1;
    private int _outerBrowRaiseIndex = -1;
    private int _browLowerIndex = -1;
    private int _upperLidRaiseIndex = -1;
    private int _cheekRaiseIndex = -1;
    private int _lidTightenIndex = -1;
    private int _noseWrinkleIndex = -1;
    private int _upperLipRaiseIndex = -1;
    private int _lipCornerPullIndex = -1;
    private int _lipCornerDepressIndex = -1;
    private int _chinRaiseIndex = -1;
    private int _lipStretchIndex = -1;
    private int _lipsPartIndex = -1;
    private int _jawDropIndex = -1;
    private int _mouthStretchIndex = -1;
    private int _blinkLeftIndex = -1;
    private int _blinkRightIndex = -1;

    // Current and target blend shape values
    private EmotionActionUnits _currentAU = new EmotionActionUnits();
    private EmotionActionUnits _targetAU = new EmotionActionUnits();

    // Animation state
    private Coroutine _transitionCoroutine;
    private float _nextBlinkTime;
    private bool _isBlinking;

    private void Start()
    {
        if (faceRenderer == null)
        {
            faceRenderer = GetComponent<SkinnedMeshRenderer>();
        }

        CacheBlendShapeIndices();
        _nextBlinkTime = Time.time + UnityEngine.Random.Range(1f, blinkInterval);
    }

    private void Update()
    {
        // Handle blinking
        if (!_isBlinking && Time.time >= _nextBlinkTime)
        {
            StartCoroutine(Blink());
        }

        // Handle breathing
        if (enableBreathing)
        {
            ApplyBreathing();
        }
    }

    /// <summary>
    /// Called from Flutter via FlutterUnityWidget message.
    /// Expects JSON with action unit values.
    /// </summary>
    public void SetEmotion(string jsonMessage)
    {
        try
        {
            var data = JsonUtility.FromJson<EmotionMessage>(jsonMessage);

            _targetAU = data.actionUnits;

            if (_transitionCoroutine != null)
            {
                StopCoroutine(_transitionCoroutine);
            }

            float duration = data.transitionDuration > 0 ? data.transitionDuration : transitionDuration;
            _transitionCoroutine = StartCoroutine(TransitionToTarget(duration));
        }
        catch (Exception e)
        {
            Debug.LogError($"Failed to parse emotion message: {e.Message}");
        }
    }

    private IEnumerator TransitionToTarget(float duration)
    {
        EmotionActionUnits startAU = _currentAU.Clone();
        float elapsed = 0f;

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float t = transitionCurve.Evaluate(elapsed / duration);

            _currentAU = EmotionActionUnits.Lerp(startAU, _targetAU, t);
            ApplyBlendShapes();

            yield return null;
        }

        _currentAU = _targetAU.Clone();
        ApplyBlendShapes();
    }

    private void ApplyBlendShapes()
    {
        if (faceRenderer == null) return;

        SetBlendShape(_innerBrowRaiseIndex, _currentAU.innerBrowRaise);
        SetBlendShape(_outerBrowRaiseIndex, _currentAU.outerBrowRaise);
        SetBlendShape(_browLowerIndex, _currentAU.browLower);
        SetBlendShape(_upperLidRaiseIndex, _currentAU.upperLidRaise);
        SetBlendShape(_cheekRaiseIndex, _currentAU.cheekRaise);
        SetBlendShape(_lidTightenIndex, _currentAU.lidTighten);
        SetBlendShape(_noseWrinkleIndex, _currentAU.noseWrinkle);
        SetBlendShape(_upperLipRaiseIndex, _currentAU.upperLipRaise);
        SetBlendShape(_lipCornerPullIndex, _currentAU.lipCornerPull);
        SetBlendShape(_lipCornerDepressIndex, _currentAU.lipCornerDepress);
        SetBlendShape(_chinRaiseIndex, _currentAU.chinRaise);
        SetBlendShape(_lipStretchIndex, _currentAU.lipStretch);
        SetBlendShape(_lipsPartIndex, _currentAU.lipsPart);
        SetBlendShape(_jawDropIndex, _currentAU.jawDrop);
        SetBlendShape(_mouthStretchIndex, _currentAU.mouthStretch);
    }

    private void SetBlendShape(int index, float value)
    {
        if (index >= 0 && faceRenderer != null)
        {
            // Blend shapes are 0-100 in Unity
            faceRenderer.SetBlendShapeWeight(index, value * 100f);
        }
    }

    private IEnumerator Blink()
    {
        _isBlinking = true;

        // Close eyes
        float elapsed = 0f;
        while (elapsed < blinkDuration / 2f)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / (blinkDuration / 2f);
            SetBlendShape(_blinkLeftIndex, t);
            SetBlendShape(_blinkRightIndex, t);
            yield return null;
        }

        // Open eyes
        elapsed = 0f;
        while (elapsed < blinkDuration / 2f)
        {
            elapsed += Time.deltaTime;
            float t = 1f - (elapsed / (blinkDuration / 2f));
            SetBlendShape(_blinkLeftIndex, t);
            SetBlendShape(_blinkRightIndex, t);
            yield return null;
        }

        SetBlendShape(_blinkLeftIndex, 0f);
        SetBlendShape(_blinkRightIndex, 0f);

        _nextBlinkTime = Time.time + UnityEngine.Random.Range(blinkInterval * 0.5f, blinkInterval * 1.5f);
        _isBlinking = false;
    }

    private void ApplyBreathing()
    {
        // Subtle chest/jaw movement for lifelike appearance
        float breathValue = (Mathf.Sin(Time.time * breathingSpeed * Mathf.PI * 2f) + 1f) * 0.02f;
        SetBlendShape(_jawDropIndex, _currentAU.jawDrop + breathValue);
    }

    private void CacheBlendShapeIndices()
    {
        if (faceRenderer == null || faceRenderer.sharedMesh == null) return;

        var mesh = faceRenderer.sharedMesh;

        // Map common blend shape names to our indices
        // Adjust these names based on your specific face model
        _innerBrowRaiseIndex = mesh.GetBlendShapeIndex("browInnerUp");
        _outerBrowRaiseIndex = mesh.GetBlendShapeIndex("browOuterUpLeft"); // or combined
        _browLowerIndex = mesh.GetBlendShapeIndex("browDownLeft");
        _upperLidRaiseIndex = mesh.GetBlendShapeIndex("eyeWideLeft");
        _cheekRaiseIndex = mesh.GetBlendShapeIndex("cheekSquintLeft");
        _lidTightenIndex = mesh.GetBlendShapeIndex("eyeSquintLeft");
        _noseWrinkleIndex = mesh.GetBlendShapeIndex("noseSneerLeft");
        _upperLipRaiseIndex = mesh.GetBlendShapeIndex("mouthUpperUpLeft");
        _lipCornerPullIndex = mesh.GetBlendShapeIndex("mouthSmileLeft");
        _lipCornerDepressIndex = mesh.GetBlendShapeIndex("mouthFrownLeft");
        _chinRaiseIndex = mesh.GetBlendShapeIndex("mouthShrugLower");
        _lipStretchIndex = mesh.GetBlendShapeIndex("mouthStretchLeft");
        _lipsPartIndex = mesh.GetBlendShapeIndex("mouthOpen");
        _jawDropIndex = mesh.GetBlendShapeIndex("jawOpen");
        _mouthStretchIndex = mesh.GetBlendShapeIndex("mouthStretchLeft");
        _blinkLeftIndex = mesh.GetBlendShapeIndex("eyeBlinkLeft");
        _blinkRightIndex = mesh.GetBlendShapeIndex("eyeBlinkRight");

        Debug.Log($"Cached blend shape indices. Found {CountValidIndices()} valid mappings.");
    }

    private int CountValidIndices()
    {
        int count = 0;
        if (_innerBrowRaiseIndex >= 0) count++;
        if (_outerBrowRaiseIndex >= 0) count++;
        if (_browLowerIndex >= 0) count++;
        if (_upperLidRaiseIndex >= 0) count++;
        if (_cheekRaiseIndex >= 0) count++;
        if (_lidTightenIndex >= 0) count++;
        if (_noseWrinkleIndex >= 0) count++;
        if (_upperLipRaiseIndex >= 0) count++;
        if (_lipCornerPullIndex >= 0) count++;
        if (_lipCornerDepressIndex >= 0) count++;
        if (_chinRaiseIndex >= 0) count++;
        if (_lipStretchIndex >= 0) count++;
        if (_lipsPartIndex >= 0) count++;
        if (_jawDropIndex >= 0) count++;
        if (_mouthStretchIndex >= 0) count++;
        if (_blinkLeftIndex >= 0) count++;
        if (_blinkRightIndex >= 0) count++;
        return count;
    }
}

[Serializable]
public class EmotionMessage
{
    public string type;
    public EmotionActionUnits actionUnits;
    public float transitionDuration;
}

[Serializable]
public class EmotionActionUnits
{
    public float innerBrowRaise;
    public float outerBrowRaise;
    public float browLower;
    public float upperLidRaise;
    public float cheekRaise;
    public float lidTighten;
    public float noseWrinkle;
    public float upperLipRaise;
    public float lipCornerPull;
    public float lipCornerDepress;
    public float chinRaise;
    public float lipStretch;
    public float lipsPart;
    public float jawDrop;
    public float mouthStretch;

    public EmotionActionUnits Clone()
    {
        return new EmotionActionUnits
        {
            innerBrowRaise = this.innerBrowRaise,
            outerBrowRaise = this.outerBrowRaise,
            browLower = this.browLower,
            upperLidRaise = this.upperLidRaise,
            cheekRaise = this.cheekRaise,
            lidTighten = this.lidTighten,
            noseWrinkle = this.noseWrinkle,
            upperLipRaise = this.upperLipRaise,
            lipCornerPull = this.lipCornerPull,
            lipCornerDepress = this.lipCornerDepress,
            chinRaise = this.chinRaise,
            lipStretch = this.lipStretch,
            lipsPart = this.lipsPart,
            jawDrop = this.jawDrop,
            mouthStretch = this.mouthStretch,
        };
    }

    public static EmotionActionUnits Lerp(EmotionActionUnits a, EmotionActionUnits b, float t)
    {
        return new EmotionActionUnits
        {
            innerBrowRaise = Mathf.Lerp(a.innerBrowRaise, b.innerBrowRaise, t),
            outerBrowRaise = Mathf.Lerp(a.outerBrowRaise, b.outerBrowRaise, t),
            browLower = Mathf.Lerp(a.browLower, b.browLower, t),
            upperLidRaise = Mathf.Lerp(a.upperLidRaise, b.upperLidRaise, t),
            cheekRaise = Mathf.Lerp(a.cheekRaise, b.cheekRaise, t),
            lidTighten = Mathf.Lerp(a.lidTighten, b.lidTighten, t),
            noseWrinkle = Mathf.Lerp(a.noseWrinkle, b.noseWrinkle, t),
            upperLipRaise = Mathf.Lerp(a.upperLipRaise, b.upperLipRaise, t),
            lipCornerPull = Mathf.Lerp(a.lipCornerPull, b.lipCornerPull, t),
            lipCornerDepress = Mathf.Lerp(a.lipCornerDepress, b.lipCornerDepress, t),
            chinRaise = Mathf.Lerp(a.chinRaise, b.chinRaise, t),
            lipStretch = Mathf.Lerp(a.lipStretch, b.lipStretch, t),
            lipsPart = Mathf.Lerp(a.lipsPart, b.lipsPart, t),
            jawDrop = Mathf.Lerp(a.jawDrop, b.jawDrop, t),
            mouthStretch = Mathf.Lerp(a.mouthStretch, b.mouthStretch, t),
        };
    }
}
