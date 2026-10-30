using System;
using UnityEngine.InputSystem;
namespace CardShopEmpire {
 public sealed class ShopInput : IDisposable {
  readonly InputActionMap map = new InputActionMap("Shop");
  public InputAction Move { get; }
  public InputAction Look { get; }
  public InputAction Sprint { get; }
  public InputAction Interact { get; }
  public InputAction Escape { get; }
  public ShopInput() {
   Move=map.AddAction("Move",InputActionType.Value);
   Move.AddCompositeBinding("2DVector").With("Up","<Keyboard>/w").With("Down","<Keyboard>/s").With("Left","<Keyboard>/a").With("Right","<Keyboard>/d");
   Look=map.AddAction("Look",InputActionType.Value,"<Mouse>/delta");
   Sprint=map.AddAction("Sprint",InputActionType.Button,"<Keyboard>/leftShift");
   Interact=map.AddAction("Interact",InputActionType.Button,"<Keyboard>/e");
   Escape=map.AddAction("Escape",InputActionType.Button,"<Keyboard>/escape");
  }
  public void Enable()=>map.Enable();
  public void Disable()=>map.Disable();
  public void Dispose()=>map.Dispose();
 }
}
