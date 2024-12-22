defmodule PoopyLoops.Repo.Migrations.AlterUsersDropPassword do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :hashed_password
      remove :confirmed_at
    end
  end
end
