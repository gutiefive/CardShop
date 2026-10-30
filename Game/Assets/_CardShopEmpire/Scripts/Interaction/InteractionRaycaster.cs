using UnityEngine;
namespace CardShopEmpire {
 public sealed class InteractionRaycaster : MonoBehaviour {
  public Camera View; public ShopHud Hud;
  [Min(0)] public float Range=3;
  public LayerMask Mask=~0;
  ShopInput input;
  void Awake(){input=new ShopInput();}
  void OnEnable(){input?.Enable();}
  void OnDisable(){input?.Disable(); if(Hud) Hud.SetFocus("");}
  void OnDestroy(){input?.Dispose();}
  void Update(){
   if(Hud.Blocked){Hud.SetFocus("");return;}
   IInteractable focus=null;
   if(Physics.Raycast(View.transform.position,View.transform.forward,out var hit,Range,Mask,QueryTriggerInteraction.Ignore))
    focus=hit.collider.GetComponentInParent<IInteractable>();
   Hud.SetFocus(focus?.Prompt??"");
   if(focus!=null && input.Interact.WasPressedThisFrame()) focus.Interact(Hud);
  }
 }
}
