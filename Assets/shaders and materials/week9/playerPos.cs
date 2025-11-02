using UnityEngine;

public class playerPos : MonoBehaviour
{
    public Material shader1Material;
    public Material shader2Material;
    public GameObject sphere;
    public float distortRadius = 2f;
    public float interactionRadius = 2f;
    public float scallopBoost = 0.05f;

    void Update()
    {
        if (sphere != null)
        {
            if (shader1Material != null)
            {
                shader1Material.SetVector("_SpherePos", sphere.transform.position);
                shader1Material.SetFloat("_DistortRadius", distortRadius);
            }
            
            if (shader2Material != null)
            {
                shader2Material.SetVector("_SpherePos", sphere.transform.position);
                shader2Material.SetFloat("_InteractionRadius", interactionRadius);
                shader2Material.SetFloat("_BoostAmount", scallopBoost);
            }
        }
    }
}
