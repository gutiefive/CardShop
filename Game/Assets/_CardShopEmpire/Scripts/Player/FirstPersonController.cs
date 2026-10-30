using UnityEngine;
namespace CardShopEmpire {
 [RequireComponent(typeof(CharacterController))]
 public sealed class FirstPersonController : MonoBehaviour {
  public Camera View;
  public ShopHud Hud;
  [Min(0)] public float WalkSpeed=3, SprintSpeed=5, Sensitivity=0.12f, Acceleration=14;
  CharacterController controller; ShopInput input; Vector3 velocity; float pitch, vertical;
  void Awake(){ controller=GetComponent<CharacterController>(); input=new ShopInput(); }
  void OnEnable(){ input?.Enable(); }
  void OnDisable(){ input?.Disable(); Cursor.lockState=CursorLockMode.None; Cursor.visible=true; }
  void OnDestroy(){ input?.Dispose(); }
  void Update(){
   if(input.Escape.WasPressedThisFrame()) Hud.Escape();
   bool blocked=Hud.Blocked;
   Cursor.lockState=blocked?CursorLockMode.None:CursorLockMode.Locked; Cursor.visible=blocked;
   if(blocked){velocity=Vector3.zero;return;}
   Vector2 look=input.Look.ReadValue<Vector2>()*Sensitivity;
   transform.Rotate(0,look.x,0); pitch=Mathf.Clamp(pitch-look.y,-85,85); View.transform.localRotation=Quaternion.Euler(pitch,0,0);
   Vector2 move=Vector2.ClampMagnitude(input.Move.ReadValue<Vector2>(),1);
   Vector3 target=(transform.right*move.x+transform.forward*move.y)*(input.Sprint.IsPressed()?SprintSpeed:WalkSpeed);
   velocity=Vector3.MoveTowards(velocity,target,Acceleration*Time.deltaTime);
   vertical=controller.isGrounded && vertical<0?-2:vertical-20*Time.deltaTime;
   controller.Move((velocity+Vector3.up*vertical)*Time.deltaTime);
  }
 }
}
