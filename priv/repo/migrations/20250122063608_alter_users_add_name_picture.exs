defmodule PoopyLoops.Repo.Migrations.AlterUsersAddNamePicture do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string, null: false
      add :picture, :string
    end
  end
end
