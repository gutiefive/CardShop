using UnityEngine;
namespace CardShopEmpire {
 public sealed class ShopSign : MonoBehaviour, IInteractable {
  [SerializeField] bool open;
  public string Prompt => "E · Set shop " + (open?"closed":"open");
  public void Interact(ShopHud hud){open=!open; hud.Notify(open?"Shop sign: OPEN":"Shop sign: CLOSED");}
 }
}
