CREATE TABLE job_version_facets (
  uuid               UUID PRIMARY KEY,
  created_at         TIMESTAMPTZ NOT NULL,
  job_version_uuid   UUID NOT NULL,
  run_uuid           UUID REFERENCES runs(uuid),
  lineage_event_time TIMESTAMPTZ NOT NULL,
  lineage_event_type VARCHAR(64) NOT NULL,
  name               VARCHAR(255) NOT NULL,
  facet              JSONB NOT NULL
);

CREATE UNIQUE INDEX job_version_facets_job_version_uuid_name_idx
    ON job_version_facets (job_version_uuid, name);
