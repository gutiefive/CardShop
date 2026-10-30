using System;
using UnityEngine;
namespace CardShopEmpire {
 public enum ProductType { BoosterPack, HobbyBox }
 public static class ProductRules {
  public static bool IsValid(string id, string name, string description, float cost, float retail) =>
   !string.IsNullOrWhiteSpace(id) && !string.IsNullOrWhiteSpace(name) && !string.IsNullOrWhiteSpace(description) &&
   !float.IsNaN(cost) && !float.IsInfinity(cost) && !float.IsNaN(retail) && !float.IsInfinity(retail) && cost >= 0 && retail >= cost;
 }
 [CreateAssetMenu(menuName="Card Shop Empire/Product")]
 public sealed class ProductDefinition : ScriptableObject {
  [SerializeField] string stableId;
  [SerializeField] string displayName;
  [SerializeField, TextArea] string description;
  [SerializeField] float basePurchasePrice;
  [SerializeField] float baseRetailPrice;
  [SerializeField] ProductType productType;
  public string StableId => stableId;
  public string DisplayName => displayName;
  public string Description => description;
  public float BasePurchasePrice => basePurchasePrice;
  public float BaseRetailPrice => baseRetailPrice;
  public ProductType Type => productType;
  public bool IsValid => ProductRules.IsValid(stableId, displayName, description, basePurchasePrice, baseRetailPrice) && Enum.IsDefined(typeof(ProductType), productType);
  public void Initialize(string id, string title, string text, float purchase, float retail, ProductType type) {
   if (!ProductRules.IsValid(id,title,text,purchase,retail) || !Enum.IsDefined(typeof(ProductType),type)) throw new ArgumentException("Invalid product definition");
   stableId=id; displayName=title; description=text; basePurchasePrice=purchase; baseRetailPrice=retail; productType=type;
  }
 }
}
