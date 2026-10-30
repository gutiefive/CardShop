using UnityEngine;
namespace CardShopEmpire {
 public sealed class ProductInteractable : MonoBehaviour, IInteractable {
  public ProductDefinition Product;
  public string Prompt => Product ? "E · Inspect " + Product.DisplayName : "";
  public void Interact(ShopHud hud){if(Product) hud.Inspect(Product);}
 }
}
