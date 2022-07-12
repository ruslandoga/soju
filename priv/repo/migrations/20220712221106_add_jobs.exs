defmodule Soju.Repo.Migrations.AddJobs do
  use Ecto.Migration

  def change do
    create table(:soju_jobs, primary_key: false) do
      add :id, :binary, primary_key: true, null: false
      add :worker, :text, null: false
      add :status, :integer, null: false, default: 0
      add :errors, :json, null: false, default: "[]"
      add :attempts, :integer, null: false, default: 0
      add :scheduled_at, :naive_datetime, null: false
      add :args, :json, null: false
    end
  end
end
