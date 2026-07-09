class AddCompanyIdAndAssetTypeIndexToAssets < ActiveRecord::Migration[8.0]
  def change
    add_index :assets, [ :company_id, :asset_type ]
  end
end
