import Icon from "../components/Icon";

export default function IdentityStrip() {
  return (
    <div className="identity-strip container">
      <span>A LINUX DESKTOP WITH A LOCAL HEART</span>
      <span>Learn.</span>
      <span>Work.</span>
      <span>Create.</span>
      <span className="strip-end">
        On your terms. <Icon name="arrow" size={18} />
      </span>
    </div>
  );
}
