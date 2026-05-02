defmodule HoMonRadeau.Repo.Migrations.AddForumUrlToEditionsAndMigrateRaftLinks do
  use Ecto.Migration

  def up do
    alter table(:editions) do
      add :forum_url, :string
    end

    execute("""
    INSERT INTO raft_links (raft_id, title, url, is_public, position, inserted_at, updated_at)
    SELECT id, 'Forum', forum_url, true, 0, NOW(), NOW()
    FROM rafts
    WHERE forum_url IS NOT NULL
    """)

    alter table(:rafts) do
      remove :forum_url
    end
  end

  def down do
    alter table(:rafts) do
      add :forum_url, :string
    end

    execute("""
    UPDATE rafts r
    SET forum_url = (
      SELECT url FROM raft_links rl
      WHERE rl.raft_id = r.id AND rl.title = 'Forum' AND rl.is_public = true
      ORDER BY rl.position ASC
      LIMIT 1
    )
    """)

    execute("""
    DELETE FROM raft_links WHERE title = 'Forum'
    """)

    alter table(:editions) do
      remove :forum_url
    end
  end
end
